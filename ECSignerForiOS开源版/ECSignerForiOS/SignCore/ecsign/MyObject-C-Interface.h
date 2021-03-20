//
//  MyObject-C-Interface.h .h
//  TestC++2
//
//  Created by Jacky on 2019/6/26.
//  Copyright © 2019 Jacky. All rights reserved.
//

#ifndef MyObject_C_Interface_h__h
#define MyObject_C_Interface_h__h

class MyClassImpl
{
public:
    MyClassImpl ( void );
    ~MyClassImpl( void );
    
    void init( void );
    char* getAppCachePath(char* filePath);
    bool unzip(char* zipPath, char* outPath);
    void zip(char* filePath, char* zipPath, int level);
    bool moveFile(char* fromPath, char* toPath, char* cer_name);
    char* getAppExecutablePath(char* appPath, char* executableName);
    char* getFrameworkExecutablePath(char* filePath);
private:
    void * self;
};

#endif /* MyObject_C_Interface_h__h */
