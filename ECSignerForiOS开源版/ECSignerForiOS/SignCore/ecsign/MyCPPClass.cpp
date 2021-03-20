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

<<<<<<< HEAD
=======
char* MyCPPClass::getInjectLinkPath(void)
{
    char* result = _impl->getInjectLinkPath();
    return result;
}

>>>>>>> ff593c9cc234797beaa3d018cc9beaedf3432cfd
bool MyCPPClass::unzip(char* zipPath, char* outPath)
{
    return _impl->unzip(zipPath, outPath);
}

void MyCPPClass::zip(char* filePath, char* zipPath, int level)
{
    _impl->zip(filePath, zipPath, level);
}

<<<<<<< HEAD
=======
bool MyCPPClass::writeLibToBundle(char* libPath, char* bundlePath)
{
    return _impl->writeLibToBundle(libPath, bundlePath);
}

bool MyCPPClass::removeLibInAppPath(char *path, char *libname)
{
    return _impl->removeLibInAppPath(path, libname);
}

>>>>>>> ff593c9cc234797beaa3d018cc9beaedf3432cfd
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
<<<<<<< HEAD
=======

int MyCPPClass::optool_do(int argc, char **argv)
{
    int result = _impl->optool_do(argc, argv);
    return result;
}

bool MyCPPClass::MakeRsaKeySSL(const char *savePrivateKeyFilePath, const  char *savePublicKeyFilePath) {
    int             ret = 0;
    RSA             *r = NULL;
    BIGNUM          *bne = NULL;
    BIO             *bp_public = NULL, *bp_private = NULL;

    int             bits = 2048;
    unsigned long   e = RSA_F4;

    // 1. generate rsa key
    bne = BN_new();
    ret = BN_set_word(bne, e);
    if (ret != 1) {
        fprintf(stderr, "MakeLocalKeySSL BN_set_word err \n");
        goto free_all;
    }

    r = RSA_new();
    ret = RSA_generate_key_ex(r, bits, bne, NULL);
    if (ret != 1) {
        fprintf(stderr, "MakeLocalKeySSL RSA_generate_key_ex err \n");
        goto free_all;
    }

    // 2. save public key
    if (savePublicKeyFilePath != NULL) {
        bp_public = BIO_new_file(savePublicKeyFilePath, "w+");
        ret = PEM_write_bio_RSAPublicKey(bp_public, r);
        if (ret != 1) {
            fprintf(stderr, "MakeLocalKeySSL PEM_write_bio_RSAPublicKey err \n");
            goto free_all;
        }
    }

    // 3. save private key
    if (savePrivateKeyFilePath != NULL) {
        bp_private = BIO_new_file(savePrivateKeyFilePath, "w+");
        ret = PEM_write_bio_RSAPrivateKey(bp_private, r, NULL, NULL, 0, NULL, NULL);
    }

    // 4. free
free_all:

    BIO_free_all(bp_public);
    BIO_free_all(bp_private);
    RSA_free(r);
    BN_free(bne);

    return (ret == 1);
}


bool MyCPPClass::MakeCsrSSL(const  char * keyFilePath, const  char *email, const  char *name, const  char *country, const  char *saveCsrFilePath) {
    int             ret = 0;
    RSA             *r = NULL;
    BIGNUM          *bne = NULL;

    int             nVersion = 1;
    int             bits = 2048;
    unsigned long   e = RSA_F4;

    X509_REQ        *x509_req = NULL;
    X509_NAME       *x509_name = NULL;
    EVP_PKEY        *pKey = NULL;
    RSA             *tem = NULL;
    BIO             *out = NULL, *keyFileBIO = NULL;
    FILE            *pubKeyFile = NULL;

    if (strlen(saveCsrFilePath) == 0) {
        fprintf(stderr, "MakeLocalCsrSSLApi save path is empty\n");
        return false;
    }

    //not exists public key file, create one immediately.
    if (strlen(keyFilePath) == 0) {
        // 1. generate rsa key
        bne = BN_new();
        ret = BN_set_word(bne, e);
        if (ret != 1) {
            fprintf(stderr, "MakeLocalCsrSSLApi BN_set_word err\n");
            goto free_all;
        }

        r = RSA_new();
        ret = RSA_generate_key_ex(r, bits, bne, NULL);
        if (ret != 1) {
            fprintf(stderr, "MakeLocalCsrSSLApi RSA_generate_key_ex err\n");
            goto free_all;
        }
    } else { //open it
        pubKeyFile = fopen(keyFilePath, "r");
        if (pubKeyFile == NULL) {
            fprintf(stderr, "MakeLocalCsrSSLApi opening file %s err\n", keyFilePath);
            goto free_all;
        }

        keyFileBIO = BIO_new_file(keyFilePath, "r");
        if (keyFileBIO == NULL) {
            fprintf(stderr, "MakeLocalCsrSSLApi BIO_new_file err %s\n", keyFilePath);
            goto free_all;
        }

        r = PEM_read_bio_RSAPrivateKey(keyFileBIO, NULL, NULL, NULL);
        if (r == NULL) {
            fprintf(stderr, "MakeLocalCsrSSLApi PEM_read_bio_RSAPrivateKey err\n");
            goto free_all;
        }

        /*
        //从csr文件中获取私钥
        BIO* bio = bio_open_default(csrFilePath, "r", 1);
        r = PEM_read_bio_RSAPrivateKey(bio, NULL, NULL, NULL);
        if (r == NULL) {
            fprintf(stderr, "Error PEM_read_RSAPublicKey file %s\n", savePrivateKeyFilePath);
            return false;
        }*/
    }

    // 2. set version of x509 req
    x509_req = X509_REQ_new();
    ret = X509_REQ_set_version(x509_req, nVersion);
    if (ret != 1) {
        fprintf(stderr, "MakeLocalCsrSSLApi X509_REQ_set_version err\n");
        goto free_all;
    }

    // 3. set subject of x509 req
    x509_name = X509_REQ_get_subject_name(x509_req); //x509_req->req_info.subject;

    ret = X509_NAME_add_entry_by_txt(x509_name, "emailAddress", MBSTRING_ASC, (const unsigned char*)email, -1, -1, 0);
    if (ret != 1) {
        fprintf(stderr, "MakeLocalCsrSSLApi X509_NAME_add_entry_by_txt emailAddress err\n");
        goto free_all;
    }

    ret = X509_NAME_add_entry_by_txt(x509_name, "CN", MBSTRING_ASC, (const unsigned char*)name, -1, -1, 0);
    if (ret != 1) {
        fprintf(stderr, "MakeLocalCsrSSLApi X509_NAME_add_entry_by_txt CN err\n");
        goto free_all;
    }

    ret = X509_NAME_add_entry_by_txt(x509_name, "C", MBSTRING_ASC, (const unsigned char*)country, -1, -1, 0);
    if (ret != 1) {
        fprintf(stderr, "MakeLocalCsrSSLApi X509_NAME_add_entry_by_txt C err\n");
        goto free_all;
    }

    // 4. set public key of x509 req
    pKey = EVP_PKEY_new();
    EVP_PKEY_assign_RSA(pKey, r);
    r = NULL;   // will be free rsa when EVP_PKEY_free(pKey)

    ret = X509_REQ_set_pubkey(x509_req, pKey);
    if (ret != 1) {
        fprintf(stderr, "MakeLocalCsrSSLApi X509_REQ_set_pubkey err\n");
        goto free_all;
    }

    // 5. set sign key of x509 req
    ret = X509_REQ_sign(x509_req, pKey, EVP_sha1());    // return x509_req->signature->length
    if (ret <= 0) {
        fprintf(stderr, "MakeLocalCsrSSLApi X509_REQ_sign err\n");
        goto free_all;
    }

    out = BIO_new_file(saveCsrFilePath, "w");
    ret = PEM_write_bio_X509_REQ(out, x509_req);

    // 6. free
free_all:
    BIO_free_all(keyFileBIO);
    X509_REQ_free(x509_req);
    BIO_free_all(out);

    EVP_PKEY_free(pKey);
    BN_free(bne);
    if (pubKeyFile) fclose(pubKeyFile);

    return (ret == 1);
}

char* MyCPPClass::readPemContent(const char* pemFilePath) {
    
    int  ret = 0;
    FILE *pemFile = NULL;
    RSA * rsa = NULL;

    pemFile = fopen(pemFilePath, "rw");
    if (pemFile == NULL) {
        fprintf(stderr, "MakeLocalPemSSL fopen savePemFilePath err \n");
    }
    
    char* name = NULL;
    char* header = NULL;
    unsigned char* data = NULL;
    long length;
    
    ret = PEM_read((FILE *)pemFile, &name, &header, &data, &length);
    if (ret != 1) {
        fprintf(stderr, "failed to Read PEM \n");
    }
    
    return (char *)data;
}


bool MyCPPClass::MakePemSSL(const char* cerFilePath, const char* savePemFilePath) {
    int      ret = 0;
    X509 *x509 = NULL;
    FILE    *cerFile = NULL, *pemFile = NULL;

    cerFile = fopen(cerFilePath, "rb");
    if (cerFile == NULL) {
        fprintf(stderr, "MakeLocalPemSSL fopen cerFilePath err \n");
        goto free_all;
    }

    pemFile = fopen(savePemFilePath, "w+");
    if (pemFile == NULL) {
        fprintf(stderr, "MakeLocalPemSSL fopen savePemFilePath err \n");
        goto free_all;
    }

    x509 = d2i_X509_fp(cerFile, NULL);
    if (x509 == NULL) {
        fprintf(stderr, "MakeLocalPemSSL failed to parse to X509 from cerFile \n");
        goto free_all;
    }

    ret = PEM_write_X509(pemFile, x509);
    if (ret != 1) {
        fprintf(stderr, "MakeLocalPemSSL failed to PEM_write_X509 \n");
        goto free_all;
    }

free_all:
    if (cerFile) fclose(cerFile);
    if (pemFile) fclose(pemFile);

    return (ret == 1);
}

bool MyCPPClass::MakeP12SSL(const char* keyFilePath, const char* pemFilePath, const char* pwd, const char* saveP12FilePath) {
    int ret = 0;
    FILE *p12File = NULL;
    EVP_PKEY *pKey = NULL;
    X509 *cert = NULL;
    PKCS12 *p12 = NULL;
    BIO *keyFileBIO = NULL, *pemFileBIO = NULL;
    RSA  *r = NULL;

    keyFileBIO = BIO_new_file(keyFilePath, "r");
    if (keyFileBIO == NULL) {
        fprintf(stderr, "MakeP12SSL BIO_new_file err %s\n", keyFilePath);
        goto free_all;
    }

    r = PEM_read_bio_RSAPrivateKey(keyFileBIO, NULL, NULL, NULL);
    if (r == NULL) {
        fprintf(stderr, "MakeP12SSL PEM_read_bio_RSAPrivateKey err\n");
        goto free_all;
    }

    pKey = EVP_PKEY_new();
    EVP_PKEY_assign_RSA(pKey, r);
    r = NULL;   // will be free rsa when EVP_PKEY_free(pKey)

    pemFileBIO = BIO_new_file(pemFilePath, "r");
    if (pemFileBIO == NULL) {
        fprintf(stderr, "MakeP12SSL BIO_new_file err %s\n", pemFilePath);
        goto free_all;
    }

    cert = PEM_read_bio_X509(pemFileBIO, NULL, NULL, NULL);
    if (cert == NULL) {
        fprintf(stderr, "MakeP12SSL PEM_read_bio_X509 err\n");
        goto free_all;
    }

    p12 = PKCS12_create(pwd, "", pKey, cert, NULL, 0, 0, 0, 0, 0);
    if (p12 == NULL) {
        fprintf(stderr, "MakeP12SSL PKCS12_create err\n");
        goto free_all;
    }

    p12File = fopen(saveP12FilePath, "w+");
    if (p12File == NULL) {
        fprintf(stderr, "MakeP12SSL fopen err %s\n", saveP12FilePath);
        goto free_all;
    }

    ret = i2d_PKCS12_fp(p12File, p12);
    if (ret != 1) {
        fprintf(stderr, "MakeP12SSL i2d_PKCS12_fp err\n");
        goto free_all;
    }

free_all:
    BIO_free_all(keyFileBIO);
    BIO_free_all(pemFileBIO);
    EVP_PKEY_free(pKey);
    PKCS12_free(p12);
    if (p12File) fclose(p12File);

    return (ret == 1);
}
>>>>>>> ff593c9cc234797beaa3d018cc9beaedf3432cfd
