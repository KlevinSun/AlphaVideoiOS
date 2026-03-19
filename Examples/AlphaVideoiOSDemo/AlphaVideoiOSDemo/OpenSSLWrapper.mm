//
//  OpenSSLWrapper.cpp
//  AlphaVideoiOSDemo
//
//  Created by sun.kai on 2023/7/27.
//  Copyright © 2023 lvpengwei. All rights reserved.
//

#include "OpenSSLWrapper.hpp"
#include <openssl/asn1.h>


static int RMASN1ReadInteger(const uint8_t **pp, long omax)
{
    int tag, asn1Class;
    long length;
    int value = 0;
    ASN1_get_object(pp, &length, &tag, &asn1Class, omax);
    if (tag == V_ASN1_INTEGER)
    {
        for (int i = 0; i < length; i++)
        {
            value = value * 0x100 + (*pp)[i];
        }
    }
    *pp += length;
    return value;
}
