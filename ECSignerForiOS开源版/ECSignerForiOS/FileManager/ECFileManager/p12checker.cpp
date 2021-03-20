//
//  p12checker.cpp
//  ECSignerForiOS
//
//  Created by Even on 2020/9/12.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#include "p12checker.h"
#include <openssl/pem.h>
#include <openssl/x509v3.h>
#include <openssl/ssl.h>
#include <openssl/crypto.h>
#include <openssl/ocsp.h>
#include <openssl/pem.h>
#include <iostream>
#include <sstream>
#include <vector>
#include <map>
#include <string>
#include "ocsp.h"
#include <unistd.h>     //for select
#include "asn1t.h"
#include "ossl_typ.h"
#include <sys/time.h>

using std::cout;
using std::endl;
using std::stringstream;
using std::map;
using std::vector;
using std::string;

//----------------------------------------------------------------------
vector<string> ocsp_urls(X509 *x509)
{
    vector<string> list;
    STACK_OF(OPENSSL_STRING) *ocsp_list = X509_get1_ocsp(x509);
    for (int j = 0; j < sk_OPENSSL_STRING_num(ocsp_list); j++)
    {
        list.push_back( string( sk_OPENSSL_STRING_value(ocsp_list, j) ) );
    }
    X509_email_free(ocsp_list);
    return list;
}
//----------------------------------------------------------------------
int prepareRequest(OCSP_REQUEST **req, X509 *cert, const EVP_MD *cert_id_md,X509 *issuer,
                   STACK_OF(OCSP_CERTID) *ids)
{
    OCSP_CERTID *id;
    if(!issuer)
    {
        std::cerr << "No issuer certificate specified" << endl;
        //BIO_printf(bio_err, "No issuer certificate specified\n");
        return 0;
    }
    if(!*req) *req = OCSP_REQUEST_new();
    if(!*req) goto err;
    id = OCSP_cert_to_id(cert_id_md, cert, issuer);
    if(!id || !sk_OCSP_CERTID_push(ids, id)) goto err;
    if(!OCSP_request_add0_id(*req, id)) goto err;
    return 1;
    
err:
    std::cerr << "Error Creating OCSP request" << endl;
    //BIO_printf(bio_err, "Error Creating OCSP request\n");
    return 0;
}
//----------------------------------------------------------------------
OCSP_RESPONSE * queryResponder(BIO *err, BIO *cbio, char *path,
                               char *host, OCSP_REQUEST *req, int req_timeout)
{
    int fd;
    int rv;
    int i;
    OCSP_REQ_CTX *ctx = NULL;
    OCSP_RESPONSE *rsp = NULL;
    fd_set confds;
    struct timeval tv;
    
    if (req_timeout != -1)
        BIO_set_nbio(cbio, 1);
    
    rv = BIO_do_connect(cbio);
    
    if ((rv <= 0) && ((req_timeout == -1) || !BIO_should_retry(cbio)))
    {
        std::cerr << "Error connecting BIO" << endl;
        return NULL;
    }
    
    if (BIO_get_fd(cbio, &fd) <= 0)
    {
        std::cerr << "Can't get connection fd" << endl;
        goto err;
    }
    
    if (req_timeout != -1 && rv <= 0)
    {
        FD_ZERO(&confds);
        FD_SET(fd, &confds);
        tv.tv_usec = 0;
        tv.tv_sec = req_timeout;
        rv = select(fd + 1, NULL, &confds, NULL, &tv);
        if (rv == 0)
        {
            std::cerr << "Timeout on connect" << endl;
            //BIO_puts(err, "Timeout on connect\n");
            return NULL;
        }
    }
    
    ctx = OCSP_sendreq_new(cbio, path, NULL, -1);
    if (!ctx)
        return NULL;
    
    if (!OCSP_REQ_CTX_add1_header(ctx, "Host", host))
        goto err;
    
    if (!OCSP_REQ_CTX_set1_req(ctx, req))
        goto err;
    
    for (;;)
    {
        rv = OCSP_sendreq_nbio(&rsp, ctx);
        if (rv != -1)
            break;
        if (req_timeout == -1)
            continue;
        FD_ZERO(&confds);
        FD_SET(fd, &confds);
        tv.tv_usec = 0;
        tv.tv_sec = req_timeout;
        if (BIO_should_read(cbio))
            rv = select(fd + 1, &confds, NULL, NULL, &tv);
        else if (BIO_should_write(cbio))
            rv = select(fd + 1, NULL, &confds, NULL, &tv);
        else
        {
            std::cerr << "Unexpected retry condition" << endl;
            goto err;
        }
        if (rv == 0)
        {
            std::cerr << "Timeout on request" << endl;
            break;
        }
        if (rv == -1)
        {
            std::cerr << "Select error" << endl;
            break;
        }
        
    }
err:
    if (ctx)
        OCSP_REQ_CTX_free(ctx);
    
    return rsp;
}
//----------------------------------------------------------------------
OCSP_RESPONSE * sendRequest(BIO *err, OCSP_REQUEST *req,
                            char *host, char *path, char *port, int use_ssl,
                            int req_timeout)
{
    BIO *cbio = NULL;
    OCSP_RESPONSE *resp = NULL;
    cbio = BIO_new_connect(host);
    if (cbio && port && use_ssl==0)
    {
        BIO_set_conn_port(cbio, port);
        resp = queryResponder(err, cbio, path, host, req, req_timeout);
        if (!resp)
            std::cerr << "Error querying OCSP responder" << endl;
    }
    if (cbio)
        BIO_free_all(cbio);
    return resp;
}


int parseResponse(OCSP_RESPONSE *resp)
{
    int is_revoked = 0;
    OCSP_BASICRESP *br = OCSP_response_get1_basic(resp);

    OCSP_SINGLERESP* single = OCSP_resp_get0(br, 0);
    OCSP_CERTSTATUS *cst = single->certStatus;
    if (cst->type == V_OCSP_CERTSTATUS_REVOKED)
    {
        is_revoked = -1;
    }

    OCSP_BASICRESP_free(br);
    return is_revoked;
}

//----------------------------------------------------------------------
int checkCertOCSP(X509 *x509, X509 *issuer)
{
    int is_revoked=-1;
    
    BIO *bio_out = BIO_new_fp(stdout, BIO_NOCLOSE|BIO_FP_TEXT);
    BIO *bio_err = BIO_new_fp(stderr, BIO_NOCLOSE|BIO_FP_TEXT);
    
    if (issuer)
    {
        //build ocsp request
        OCSP_REQUEST *req = NULL;
//        STACK_OF(CONF_VALUE) *headers = NULL;
        STACK_OF(OCSP_CERTID) *ids = sk_OCSP_CERTID_new_null();
        const EVP_MD *cert_id_md = EVP_sha1();
        prepareRequest(&req, x509, cert_id_md, issuer, ids);
        
        //loop through OCSP urls
        STACK_OF(OPENSSL_STRING) *ocsp_list = X509_get1_ocsp(x509);
        for (int j = 0; j < sk_OPENSSL_STRING_num(ocsp_list) && is_revoked==-1; j++)
        {
            char *host = NULL, *port = NULL, *path = NULL;
            int use_ssl, req_timeout = 30;
            string ocsp_url0 = string( sk_OPENSSL_STRING_value(ocsp_list, j) );
            
            char *ocsp_url = sk_OPENSSL_STRING_value(ocsp_list, j);
            if (OCSP_parse_url(ocsp_url, &host, &port, &path, &use_ssl) && !use_ssl)
            {
                //send ocsp request
                OCSP_RESPONSE *resp = sendRequest(bio_err, req, host, path, port, use_ssl, req_timeout);
                if (resp)
                {
                    //see crypto/ocsp/ocsp_prn.c for examples parsing OCSP responses
                    int responder_status = OCSP_response_status(resp);
                    
                    //parse response
                    if (resp && responder_status == OCSP_RESPONSE_STATUS_SUCCESSFUL)
                    {
//                        OCSP_RESPONSE_print(bio_out, resp, 0);
                        is_revoked = parseResponse(resp);
                    }
                    OCSP_RESPONSE_free(resp);
                }
            }
            OPENSSL_free(host);
            OPENSSL_free(path);
            OPENSSL_free(port);
        }
        X509_email_free(ocsp_list);
        OCSP_REQUEST_free(req);
    }
    
    BIO_free(bio_out);
    BIO_free(bio_err);
    return is_revoked;
}
//----------------------------------------------------------------------
string commonName(X509 *x509)
{
    X509_NAME *subject = X509_get_subject_name(x509);
    int subject_position = X509_NAME_get_index_by_NID(subject, NID_commonName, 0);
    X509_NAME_ENTRY *entry = subject_position==-1 ? NULL : X509_NAME_get_entry(subject, subject_position);
    ASN1_STRING *d = X509_NAME_ENTRY_get_data(entry);
    return string( (char*)d->data, ASN1_STRING_length(d) );
}
//----------------------------------------------------------------------
int isRevokedByOCSP(X509 * x509, const char issuer_bytes[])
{
    BIO *bio_mem2 = BIO_new(BIO_s_mem());
    BIO_puts(bio_mem2, issuer_bytes);
    X509 * issuer = PEM_read_bio_X509(bio_mem2, NULL, NULL, NULL);
    int status = checkCertOCSP(x509, issuer);
    cout << commonName(x509) << " certificate, ";
    cout << "isRevokedByOCSP: " << status << endl;
    BIO_free(bio_mem2);
    X509_free(issuer);
    
    return status;
}
//----------------------------------------------------------------------


bool isP12Revoked(X509 * x509, bool g3) {
    
    OpenSSL_add_all_algorithms();
    
    //苹果根证书  https://developer.apple.com/certificationauthority/AppleWWDRCA.cer
    const char issuer1_bytes[] = "-----BEGIN CERTIFICATE-----" "\n"
    "MIIEIjCCAwqgAwIBAgIIAd68xDltoBAwDQYJKoZIhvcNAQEFBQAwYjELMAkGA1UE" "\n"
    "BhMCVVMxEzARBgNVBAoTCkFwcGxlIEluYy4xJjAkBgNVBAsTHUFwcGxlIENlcnRp" "\n"
    "ZmljYXRpb24gQXV0aG9yaXR5MRYwFAYDVQQDEw1BcHBsZSBSb290IENBMB4XDTEz" "\n"
    "MDIwNzIxNDg0N1oXDTIzMDIwNzIxNDg0N1owgZYxCzAJBgNVBAYTAlVTMRMwEQYD" "\n"
    "VQQKDApBcHBsZSBJbmMuMSwwKgYDVQQLDCNBcHBsZSBXb3JsZHdpZGUgRGV2ZWxv" "\n"
    "cGVyIFJlbGF0aW9uczFEMEIGA1UEAww7QXBwbGUgV29ybGR3aWRlIERldmVsb3Bl" "\n"
    "ciBSZWxhdGlvbnMgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggEiMA0GCSqGSIb3" "\n"
    "DQEBAQUAA4IBDwAwggEKAoIBAQDKOFSmy1aqyCQ5SOmM7uxfuH8mkbw0U3rOfGOA" "\n"
    "YXdkXqUHI7Y5/lAtFVZYcC1+xG7BSoU+L/DehBqhV8mvexj/avoVEkkVCBmsqtsq" "\n"
    "Mu2WY2hSFT2Miuy/axiV4AOsAX2XBWfODoWVN2rtCbauZ81RZJ/GXNG8V25nNYB2" "\n"
    "NqSHgW44j9grFU57Jdhav06DwY3Sk9UacbVgnJ0zTlX5ElgMhrgWDcHld0WNUEi6" "\n"
    "Ky3klIXh6MSdxmilsKP8Z35wugJZS3dCkTm59c3hTO/AO0iMpuUhXf1qarunFjVg" "\n"
    "0uat80YpyejDi+l5wGphZxWy8P3laLxiX27Pmd3vG2P+kmWrAgMBAAGjgaYwgaMw" "\n"
    "HQYDVR0OBBYEFIgnFwmpthhgi+zruvZHWcVSVKO3MA8GA1UdEwEB/wQFMAMBAf8w" "\n"
    "HwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wLgYDVR0fBCcwJTAjoCGg" "\n"
    "H4YdaHR0cDovL2NybC5hcHBsZS5jb20vcm9vdC5jcmwwDgYDVR0PAQH/BAQDAgGG" "\n"
    "MBAGCiqGSIb3Y2QGAgEEAgUAMA0GCSqGSIb3DQEBBQUAA4IBAQBPz+9Zviz1smwv" "\n"
    "j+4ThzLoBTWobot9yWkMudkXvHcs1Gfi/ZptOllc34MBvbKuKmFysa/Nw0Uwj6OD" "\n"
    "Dc4dR7Txk4qjdJukw5hyhzs+r0ULklS5MruQGFNrCk4QttkdUGwhgAqJTleMa1s8" "\n"
    "Pab93vcNIx0LSiaHP7qRkkykGRIZbVf1eliHe2iK5IaMSuviSRSqpd1VAKmuu0sw" "\n"
    "ruGgsbwpgOYJd+W+NKIByn/c4grmO7i77LpilfMFY0GCzQ87HUyVpNur+cmV6U/k" "\n"
    "TecmmYHpvPm0KdIBembhLoz2IYrF+Hjhga6/05Cdqa3zr/04GpZnMBxRpVzscYqC" "\n"
    "tGwPDBUf" "\n"
    "-----END CERTIFICATE-----" "\n";
    
    const char g3_issuer1_bytes[] = "-----BEGIN CERTIFICATE-----" "\n"
    "MIIEUTCCAzmgAwIBAgIQfK9pCiW3Of57m0R6wXjF7jANBgkqhkiG9w0BAQsFADBi" "\n"
    "MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBw" "\n"
    "bGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3Qg" "\n"
    "Q0EwHhcNMjAwMjE5MTgxMzQ3WhcNMzAwMjIwMDAwMDAwWjB1MUQwQgYDVQQDDDtB" "\n"
    "cHBsZSBXb3JsZHdpZGUgRGV2ZWxvcGVyIFJlbGF0aW9ucyBDZXJ0aWZpY2F0aW9u" "\n"
    "IEF1dGhvcml0eTELMAkGA1UECwwCRzMxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJ" "\n"
    "BgNVBAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2PWJ/KhZ" "\n"
    "C4fHTJEuLVaQ03gdpDDppUjvC0O/LYT7JF1FG+XrWTYSXFRknmxiLbTGl8rMPPbW" "\n"
    "BpH85QKmHGq0edVny6zpPwcR4YS8Rx1mjjmi6LRJ7TrS4RBgeo6TjMrA2gzAg9Dj" "\n"
    "+ZHWp4zIwXPirkbRYp2SqJBgN31ols2N4Pyb+ni743uvLRfdW/6AWSN1F7gSwe0b" "\n"
    "5TTO/iK1nkmw5VW/j4SiPKi6xYaVFuQAyZ8D0MyzOhZ71gVcnetHrg21LYwOaU1A" "\n"
    "0EtMOwSejSGxrC5DVDDOwYqGlJhL32oNP/77HK6XF8J4CjDgXx9UO0m3JQAaN4LS" "\n"
    "VpelUkl8YDib7wIDAQABo4HvMIHsMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYDVR0j" "\n"
    "BBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wRAYIKwYBBQUHAQEEODA2MDQGCCsG" "\n"
    "AQUFBzABhihodHRwOi8vb2NzcC5hcHBsZS5jb20vb2NzcDAzLWFwcGxlcm9vdGNh" "\n"
    "MC4GA1UdHwQnMCUwI6AhoB+GHWh0dHA6Ly9jcmwuYXBwbGUuY29tL3Jvb3QuY3Js" "\n"
    "MB0GA1UdDgQWBBQJ/sAVkPmvZAqSErkmKGMMl+ynsjAOBgNVHQ8BAf8EBAMCAQYw" "\n"
    "EAYKKoZIhvdjZAYCAQQCBQAwDQYJKoZIhvcNAQELBQADggEBAK1lE+j24IF3RAJH" "\n"
    "Qr5fpTkg6mKp/cWQyXMT1Z6b0KoPjY3L7QHPbChAW8dVJEH4/M/BtSPp3Ozxb8qA" "\n"
    "HXfCxGFJJWevD8o5Ja3T43rMMygNDi6hV0Bz+uZcrgZRKe3jhQxPYdwyFot30ETK" "\n"
    "XXIDMUacrptAGvr04NM++i+MZp+XxFRZ79JI9AeZSWBZGcfdlNHAwWx/eCHvDOs7" "\n"
    "bJmCS1JgOLU5gm3sUjFTvg+RTElJdI+mUcuER04ddSduvfnSXPN/wmwLCTbiZOTC" "\n"
    "NwMUGdXqapSqqdv+9poIZ4vvK7iqF0mDr8/LvOnP6pVxsLRFoszlh6oKw0E6eVza" "\n"
    "UDSdlTs=" "\n"
    "-----END CERTIFICATE-----" "\n";
    
    int status = 0;
    if (g3) {
        status = isRevokedByOCSP(x509, g3_issuer1_bytes);
    } else {
        status = isRevokedByOCSP(x509, issuer1_bytes);
    }
    
    return status == -1;
}

//根据证书组织单位来判断使用哪个根证书来检查
//G2
/*

 const char issuer1_bytes[] = "-----BEGIN CERTIFICATE-----" "\n"
 "MIIEIjCCAwqgAwIBAgIIAd68xDltoBAwDQYJKoZIhvcNAQEFBQAwYjELMAkGA1UE" "\n"
 "BhMCVVMxEzARBgNVBAoTCkFwcGxlIEluYy4xJjAkBgNVBAsTHUFwcGxlIENlcnRp" "\n"
 "ZmljYXRpb24gQXV0aG9yaXR5MRYwFAYDVQQDEw1BcHBsZSBSb290IENBMB4XDTEz" "\n"
 "MDIwNzIxNDg0N1oXDTIzMDIwNzIxNDg0N1owgZYxCzAJBgNVBAYTAlVTMRMwEQYD" "\n"
 "VQQKDApBcHBsZSBJbmMuMSwwKgYDVQQLDCNBcHBsZSBXb3JsZHdpZGUgRGV2ZWxv" "\n"
 "cGVyIFJlbGF0aW9uczFEMEIGA1UEAww7QXBwbGUgV29ybGR3aWRlIERldmVsb3Bl" "\n"
 "ciBSZWxhdGlvbnMgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggEiMA0GCSqGSIb3" "\n"
 "DQEBAQUAA4IBDwAwggEKAoIBAQDKOFSmy1aqyCQ5SOmM7uxfuH8mkbw0U3rOfGOA" "\n"
 "YXdkXqUHI7Y5/lAtFVZYcC1+xG7BSoU+L/DehBqhV8mvexj/avoVEkkVCBmsqtsq" "\n"
 "Mu2WY2hSFT2Miuy/axiV4AOsAX2XBWfODoWVN2rtCbauZ81RZJ/GXNG8V25nNYB2" "\n"
 "NqSHgW44j9grFU57Jdhav06DwY3Sk9UacbVgnJ0zTlX5ElgMhrgWDcHld0WNUEi6" "\n"
 "Ky3klIXh6MSdxmilsKP8Z35wugJZS3dCkTm59c3hTO/AO0iMpuUhXf1qarunFjVg" "\n"
 "0uat80YpyejDi+l5wGphZxWy8P3laLxiX27Pmd3vG2P+kmWrAgMBAAGjgaYwgaMw" "\n"
 "HQYDVR0OBBYEFIgnFwmpthhgi+zruvZHWcVSVKO3MA8GA1UdEwEB/wQFMAMBAf8w" "\n"
 "HwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wLgYDVR0fBCcwJTAjoCGg" "\n"
 "H4YdaHR0cDovL2NybC5hcHBsZS5jb20vcm9vdC5jcmwwDgYDVR0PAQH/BAQDAgGG" "\n"
 "MBAGCiqGSIb3Y2QGAgEEAgUAMA0GCSqGSIb3DQEBBQUAA4IBAQBPz+9Zviz1smwv" "\n"
 "j+4ThzLoBTWobot9yWkMudkXvHcs1Gfi/ZptOllc34MBvbKuKmFysa/Nw0Uwj6OD" "\n"
 "Dc4dR7Txk4qjdJukw5hyhzs+r0ULklS5MruQGFNrCk4QttkdUGwhgAqJTleMa1s8" "\n"
 "Pab93vcNIx0LSiaHP7qRkkykGRIZbVf1eliHe2iK5IaMSuviSRSqpd1VAKmuu0sw" "\n"
 "ruGgsbwpgOYJd+W+NKIByn/c4grmO7i77LpilfMFY0GCzQ87HUyVpNur+cmV6U/k" "\n"
 "TecmmYHpvPm0KdIBembhLoz2IYrF+Hjhga6/05Cdqa3zr/04GpZnMBxRpVzscYqC" "\n"
 "tGwPDBUf" "\n"
 "-----END CERTIFICATE-----" "\n";
 */


//G3
/*
 const char issuer1_bytes[] = "-----BEGIN CERTIFICATE-----" "\n"
 "MIIEUTCCAzmgAwIBAgIQfK9pCiW3Of57m0R6wXjF7jANBgkqhkiG9w0BAQsFADBi" "\n"
 "MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBw" "\n"
 "bGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3Qg" "\n"
 "Q0EwHhcNMjAwMjE5MTgxMzQ3WhcNMzAwMjIwMDAwMDAwWjB1MUQwQgYDVQQDDDtB" "\n"
 "cHBsZSBXb3JsZHdpZGUgRGV2ZWxvcGVyIFJlbGF0aW9ucyBDZXJ0aWZpY2F0aW9u" "\n"
 "IEF1dGhvcml0eTELMAkGA1UECwwCRzMxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJ" "\n"
 "BgNVBAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2PWJ/KhZ" "\n"
 "C4fHTJEuLVaQ03gdpDDppUjvC0O/LYT7JF1FG+XrWTYSXFRknmxiLbTGl8rMPPbW" "\n"
 "BpH85QKmHGq0edVny6zpPwcR4YS8Rx1mjjmi6LRJ7TrS4RBgeo6TjMrA2gzAg9Dj" "\n"
 "+ZHWp4zIwXPirkbRYp2SqJBgN31ols2N4Pyb+ni743uvLRfdW/6AWSN1F7gSwe0b" "\n"
 "5TTO/iK1nkmw5VW/j4SiPKi6xYaVFuQAyZ8D0MyzOhZ71gVcnetHrg21LYwOaU1A" "\n"
 "0EtMOwSejSGxrC5DVDDOwYqGlJhL32oNP/77HK6XF8J4CjDgXx9UO0m3JQAaN4LS" "\n"
 "VpelUkl8YDib7wIDAQABo4HvMIHsMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYDVR0j" "\n"
 "BBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wRAYIKwYBBQUHAQEEODA2MDQGCCsG" "\n"
 "AQUFBzABhihodHRwOi8vb2NzcC5hcHBsZS5jb20vb2NzcDAzLWFwcGxlcm9vdGNh" "\n"
 "MC4GA1UdHwQnMCUwI6AhoB+GHWh0dHA6Ly9jcmwuYXBwbGUuY29tL3Jvb3QuY3Js" "\n"
 "MB0GA1UdDgQWBBQJ/sAVkPmvZAqSErkmKGMMl+ynsjAOBgNVHQ8BAf8EBAMCAQYw" "\n"
 "EAYKKoZIhvdjZAYCAQQCBQAwDQYJKoZIhvcNAQELBQADggEBAK1lE+j24IF3RAJH" "\n"
 "Qr5fpTkg6mKp/cWQyXMT1Z6b0KoPjY3L7QHPbChAW8dVJEH4/M/BtSPp3Ozxb8qA" "\n"
 "HXfCxGFJJWevD8o5Ja3T43rMMygNDi6hV0Bz+uZcrgZRKe3jhQxPYdwyFot30ETK" "\n"
 "XXIDMUacrptAGvr04NM++i+MZp+XxFRZ79JI9AeZSWBZGcfdlNHAwWx/eCHvDOs7" "\n"
 "bJmCS1JgOLU5gm3sUjFTvg+RTElJdI+mUcuER04ddSduvfnSXPN/wmwLCTbiZOTC" "\n"
 "NwMUGdXqapSqqdv+9poIZ4vvK7iqF0mDr8/LvOnP6pVxsLRFoszlh6oKw0E6eVza" "\n"
 "UDSdlTs=" "\n"
 "-----END CERTIFICATE-----" "\n";
 */
