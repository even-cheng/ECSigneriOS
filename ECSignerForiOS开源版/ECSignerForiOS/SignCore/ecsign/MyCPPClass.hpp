//
//  MyCPPClass.hpp
//  TestC++2
//
//  Created by Jacky on 2019/6/26.
//  Copyright © 2019 Jacky. All rights reserved.
//

#ifndef MyCPPClass_hpp
#define MyCPPClass_hpp

#include <stdio.h>

class MyClassImpl;

class MyCPPClass
{
public:
    MyCPPClass ( void );
    ~MyCPPClass( void );
    
    void init( void );
    char* getAppCachePath(char* filePath);
    char* getInjectLinkPath(void);
    bool unzip(char* zipPath, char* outPath);
    void zip(char* filePath, char* zipPath, int level);
<<<<<<< HEAD
    char* getAppExecutablePath(char* appPath, char* executableName);
    bool moveFile(char* fromPath, char* toPath, char* cer_name);
    char* getFrameworkExecutablePath(char* filePath);
=======
    bool removeLibInAppPath(char* path, char* libname);
    char* getAppExecutablePath(char* appPath, char* executableName);
    bool moveFile(char* fromPath, char* toPath, char* cer_name);
    char* getFrameworkExecutablePath(char* filePath);
    bool writeLibToBundle(char* libPath, char* bundlePath);
    int optool_do(int argc, char * argv[]);
    bool MakeRsaKeySSL(const char *savePrivateKeyFilePath, const  char *savePublicKeyFilePath);
    bool MakeCsrSSL(const  char * keyFilePath, const  char *email, const  char *name, const  char *country, const  char *saveCsrFilePath);
    bool MakePemSSL(const char* cerFilePath, const char* savePemFilePath);
    bool MakeP12SSL(const char* keyFilePath, const char* pemFilePath, const char* pwd, const char* saveP12FilePath);
    char* readPemContent(const char* pemFilePath);
>>>>>>> ff593c9cc234797beaa3d018cc9beaedf3432cfd

private:
    MyClassImpl * _impl;
};


#endif /* MyCPPClass_hpp */
