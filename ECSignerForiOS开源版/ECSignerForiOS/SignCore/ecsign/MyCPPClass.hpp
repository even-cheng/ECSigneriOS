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
    char* getAppExecutablePath(char* appPath, char* executableName);
    bool moveFile(char* fromPath, char* toPath, char* cer_name);
    char* getFrameworkExecutablePath(char* filePath);


private:
    MyClassImpl * _impl;
};


#endif /* MyCPPClass_hpp */
