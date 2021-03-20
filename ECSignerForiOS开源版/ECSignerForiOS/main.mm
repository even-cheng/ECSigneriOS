//
//  main.m
//  ECSignerForiOS
//
//  Created by even on 2020/8/28.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <dlfcn.h>
#import <sys/types.h>

typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);

#if !defined(PT_DENY_ATTACH)
#define PT_DENY_ATTACH 31
#endif

// 阻止调试器attach
void disable_gdb() {
    //第一个参数path为0时, 它会自动查找 $LD_LIBRARY_PATH,$DYLD_LIBRARY_PATH, $DYLD_FALLBACK_LIBRARY_PATH 和 当前工作目录中的动态链接库.
    void * handle = dlopen(0, RTLD_GLOBAL | RTLD_NOW);
    //动态加载ptrace函数，ptrace函数的参数个数和类型，及返回类型跟ptrace_ptr_t函数指针定义的是一样的
    ptrace_ptr_t ptrace_ptr = (ptrace_ptr_t)dlsym(handle, "ptrace");
    //执行ptrace_ptr相当于执行ptrace函数
    ptrace_ptr(PT_DENY_ATTACH, 0, 0, 0);
    //关闭动态库，并且卸载
    dlclose(handle);
}

int main(int argc, char * argv[]) {
    
    #ifndef DEBUG
            disable_gdb();
    #endif
    signal(SIGPIPE, SIG_IGN);
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
