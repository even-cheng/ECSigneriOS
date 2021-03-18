//
//  main.m
//  optool
//  Copyright (c) 2014, Alex Zielenski
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import <Foundation/Foundation.h>
#import "FSArgumentParser/ArgumentParser/XPMArguments.h"
#import "FSArgumentParser/ArgumentParser/NSString+Indenter.h"
#import <sys/ttycom.h>
#import <sys/ioctl.h>
#import "defines.h"
#import "headers.h"
#import "operations.h"


NSArray* checkAllDyLibs(NSString* targetPath) {
    
    NSBundle *bundle = [NSBundle bundleWithPath:targetPath];
    NSString *executablePath = [[bundle.executablePath ?: targetPath stringByExpandingTildeInPath] stringByResolvingSymlinksInPath];
    NSData *originalData = [NSData dataWithContentsOfFile:executablePath];
    NSMutableData *binary = originalData.mutableCopy;

    struct thin_header headers[4];
    uint32_t numHeaders = 0;
    headersFromBinary(headers, binary, &numHeaders);

    uint32_t lastOffset = 0;
    NSMutableArray* arr = [NSMutableArray array];
    for (uint32_t i = 0; i < numHeaders; i++) {
             
        struct thin_header macho = headers[i];
        NSArray* dylibs = allDylibs(binary, &lastOffset, macho);
        for (NSString* content in dylibs) {
            if (![arr containsObject:content]) {
                [arr addObject:content];
            }
        }
    }
    
    return arr.copy;
}

NSArray* checkAllDyLibsForExecutable(NSString* executablePath) {
    
    executablePath = [executablePath stringByResolvingSymlinksInPath];
    NSData *originalData = [NSData dataWithContentsOfFile:executablePath];
    NSMutableData *binary = originalData.mutableCopy;

    struct thin_header headers[4];
    uint32_t numHeaders = 0;
    headersFromBinary(headers, binary, &numHeaders);

    uint32_t lastOffset = 0;
    NSMutableArray* arr = [NSMutableArray array];
    for (uint32_t i = 0; i < numHeaders; i++) {
             
        struct thin_header macho = headers[i];
        NSArray* dylibs = allDylibs(binary, &lastOffset, macho);
        for (NSString* content in dylibs) {
            if (![arr containsObject:content]) {
                [arr addObject:content];
            }
        }
    }
    
    return arr.copy;
}


int optool_do(NSArray* arguments) {
    @autoreleasepool {
        BOOL showHelp = NO;

        // Flags
        XPMArgumentSignature *weak = [XPMArgumentSignature argumentSignatureWithFormat:@"[-w --weak]"];
        XPMArgumentSignature *resign = [XPMArgumentSignature argumentSignatureWithFormat:@"[--resign]"];
        XPMArgumentSignature *target = [XPMArgumentSignature argumentSignatureWithFormat:@"[-t --target]={1,1}"];
        XPMArgumentSignature *payload = [XPMArgumentSignature argumentSignatureWithFormat:@"[-p --payload]={1,1}"];
        XPMArgumentSignature *command = [XPMArgumentSignature argumentSignatureWithFormat:@"[-c --command]={1,1}"];
        XPMArgumentSignature *backup = [XPMArgumentSignature argumentSignatureWithFormat:@"[-b --backup]"];
        XPMArgumentSignature *output = [XPMArgumentSignature argumentSignatureWithFormat:@"[-o --output]={1,1}"];
        XPMArgumentSignature *help = [XPMArgumentSignature argumentSignatureWithFormat:@"[-h --help]"];
        
        // Actions
        XPMArgumentSignature *strip = [XPMArgumentSignature argumentSignatureWithFormat:@"[s strip]"];
        XPMArgumentSignature *restore = [XPMArgumentSignature argumentSignatureWithFormat:@"[r restore]"];
        XPMArgumentSignature *install = [XPMArgumentSignature argumentSignatureWithFormat:@"[i install]"];
        XPMArgumentSignature *rename = [XPMArgumentSignature argumentSignatureWithFormat:@"[r rename]={1,2}"];
        XPMArgumentSignature *uninstall = [XPMArgumentSignature argumentSignatureWithFormat:@"[u uninstall]"];
        XPMArgumentSignature *aslr = [XPMArgumentSignature argumentSignatureWithFormat:@"[a aslr]"];
        XPMArgumentSignature *unrestrict = [XPMArgumentSignature argumentSignatureWithFormat:@"[c unrestrict]"];
        
        [strip setInjectedSignatures:[NSSet setWithObjects:target, weak, nil]];
        [restore setInjectedSignatures:[NSSet setWithObjects:target, nil]];
        [install setInjectedSignatures:[NSSet setWithObjects:target, payload, nil]];
        [uninstall setInjectedSignatures:[NSSet setWithObjects:target, payload, nil]];
        [aslr setInjectedSignatures:[NSSet setWithObjects:target, nil]];
        [unrestrict setInjectedSignatures:[NSSet setWithObjects:target, weak, nil]];
        [rename setInjectedSignatures:[NSSet setWithObjects:target, nil]];
        
        [weak setInjectedSignatures:[NSSet setWithObjects:strip, unrestrict, nil]];
        [payload setInjectedSignatures:[NSSet setWithObjects:install, uninstall, nil]];
        [command setInjectedSignatures:[NSSet setWithObjects:install, nil]];

        XPMArgumentPackage *package = [[NSProcessInfo processInfo] xpmargs_parseArgumentsWithSignatures:@[resign, command, strip, restore, install, uninstall, output, backup, aslr, help, unrestrict, rename] arguments:arguments];

        NSString *targetPath = [package firstObjectForSignature:target];
        if (!targetPath || [package unknownSwitches].count > 0 || [package booleanValueForSignature:help]) {
            // Invalid arguments, show help
            showHelp = YES;
            goto help;
        }

        {

        NSString *executablePath = targetPath;

        NSString *dylibPath  = [package firstObjectForSignature:payload];
        NSString *outputPath = executablePath;

        NSData *originalData = [NSData dataWithContentsOfFile:executablePath];
        NSMutableData *binary = originalData.mutableCopy;
        if (!binary)
            return OPErrorRead;

        struct thin_header headers[4];
        uint32_t numHeaders = 0;
        headersFromBinary(headers, binary, &numHeaders);

        if (numHeaders == 0) {
            LOG("No compatible architecture found");
            return OPErrorIncompatibleBinary;
        }

        // Loop through all of the thin headers we found for each operation
        for (uint32_t i = 0; i < numHeaders; i++) {
            struct thin_header macho = headers[i];

            if ([package booleanValueForSignature:uninstall]) {
                if (removeLoadEntryFromBinary(binary, macho, dylibPath)) {
                    LOG("Successfully removed all entries for %s", dylibPath.UTF8String);
                } else {
                    LOG("No entries for %s exist to remove", dylibPath.UTF8String);
                    return OPErrorNoEntries;
                }
            } else if ([package booleanValueForSignature:install]) {
                NSString *lc = [package firstObjectForSignature:command];
                uint32_t command = LC_LOAD_DYLIB;
                if (lc)
                    command = COMMAND(lc);
                if (command == -1) {
                    LOG("Invalid load command.");
                    return OPErrorInvalidLoadCommand;
                }

                if (insertLoadEntryIntoBinary(dylibPath, binary, macho, command)) {
                    LOG("Successfully inserted a %s command for %s", LC(command), CPU(macho.header.cputype));
                } else {
                    LOG("Failed to insert a %s command for %s", LC(command), CPU(macho.header.cputype));
                    return OPErrorInsertFailure;
                }
            } else {
                // Invalid arguments. Show help
                showHelp = YES;
                goto help;
            }
        }

        LOG("Writing executable to %s...", outputPath.UTF8String);
        if (![binary writeToFile:outputPath atomically:NO]) {
            LOG("Failed to write data. Permissions?");
            return OPErrorWriteFailure;
        }

        }

    help:
        if (showHelp) {
            struct winsize ws;
            ioctl(0, TIOCGWINSZ, &ws);

#define SHOW(SIG) LOG("%s", [[SIG xpmargs_mutableStringByIndentingToWidth:2 lineLength:ws.ws_col] UTF8String])

            LOG("optool v0.2\n");
            LOG("USAGE:");
            SHOW(@"install -c <command> -p <payload> -t <target> [-o=<output>] [-b] [--resign] Inserts an LC_LOAD command into the target binary which points to the payload. This may render some executables unusable.");
            SHOW(@"uninstall -p <payload> -t <target> [-o=<output>] [-b] [--resign] Removes any LC_LOAD commands which point to a given payload from the target binary. This may render some executables unusable.");
            SHOW(@"strip [-w] -t <target> Removes a code signature load command from the given binary.");
            SHOW(@"unrestrict [-w] -t <target> Removes a __restrict section from the given binary. The weak flag makes this a non-destructive operation which merely renames the __restrict section to something not understandable by dyld; otherwise, this operation removes all the __restrict data from the binary.");
            SHOW(@"restore -t <target> Restores any backup made on the target by this tool.");
            SHOW(@"aslr -t <target> [-o=<output>] [-b] [--resign] Removes an ASLR flag from the macho header if it exists. This may render some executables unusable");
            LOG("\nOPTIONS:");
            SHOW(@"[-w --weak] Used with the STRIP or UNRESTRICT commands to weakly remove the signature. Without this, the code signature is replaced with null bytes on the binary and its LOAD command is removed.");
            SHOW(@"[--resign] Try to repair the code signature after any operations are done. This may render some executables unusable.");
            SHOW(@"-t|--target <target> Required of all commands to specify the target executable to modify");
            SHOW(@"-p|--payload <payload> Required of the INSTALL and UNINSTALL commands to specify the path to a DYLIB to point the LOAD command to");
            SHOW(@"[-c --command] Specify which type of load command to use in INSTALL. Can be reexport for LC_REEXPORT_DYLIB, weak for LC_LOAD_WEAK_DYLIB, upward for LC_LOAD_UPWARD_DYLIB, or load for LC_LOAD_DYLIB");
            SHOW(@"[-b --backup] Backup the executable to a suffixed path (in the form of _backup.BUNDLEVERSION)");
            SHOW(@"[-h --help] Show this message");
            LOG("\n(C) 2014 Alexander S. Zielenski. Licensed under BSD");

            return ([package booleanValueForSignature:help]) ? OPErrorNone : OPErrorInvalidArguments;
        }
    }
    
    return OPErrorNone;
}


