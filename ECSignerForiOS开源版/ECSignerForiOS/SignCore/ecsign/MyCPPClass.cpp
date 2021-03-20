//
//  MyCPPClass.cpp
//  TestC++2
//
//  Created by Jacky on 2019/6/26.
//  Copyright © 2019 Jacky. All rights reserved.
//

#include "MyCPPClass.hpp"
#include "MyObject-C-Interface.h"

#include "openssl.h"
#include "ossl_typ.h"
#include "rsa.h"
#include "bn.h"
#include "pem.h"
#include "pkcs12.h"

MyCPPClass::MyCPPClass( void )
: _impl ( NULL )
{   }

void MyCPPClass::init( void )
{
    _impl = new MyClassImpl();
    _impl->init();
}

MyCPPClass::~MyCPPClass( void )
{
    if ( _impl ) { delete _impl; _impl = NULL; }
}

char* MyCPPClass::getAppCachePath (char* filePath)
{
    char* result = _impl->getAppCachePath(filePath);
    return result;
}

bool MyCPPClass::unzip(char* zipPath, char* outPath)
{
    return _impl->unzip(zipPath, outPath);
}

void MyCPPClass::zip(char* filePath, char* zipPath, int level)
{
    _impl->zip(filePath, zipPath, level);
}

bool MyCPPClass::moveFile(char* fromPath, char* toPath, char* cer_name)
{
    return _impl->moveFile(fromPath, toPath, cer_name);
}

char* MyCPPClass::getAppExecutablePath (char* appPath, char* executableName)
{
    char* result = _impl->getAppExecutablePath(appPath, executableName);
    return result;
}

char* MyCPPClass::getFrameworkExecutablePath(char* filePath)
{
    char* result = _impl->getFrameworkExecutablePath(filePath);
    return result;
}
