//
//  dump-ios-mobileprovision.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/14.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#ifdef __cplusplus

#include "OCTET_STRING.h"

extern "C" {
#endif
    
    
    OCTET_STRING_t* dumpMobileProvision(char *path);
    
#ifdef __cplusplus
}


#endif /* __OPTPARSE_H_ */
