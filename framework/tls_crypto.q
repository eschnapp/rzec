.boot.include (gdrive_root, "/framework/common.q");

.tls_crypto.on_comp_start:{
    :1b;
    };

	// encrypt RSA using public key
.tls_crypto.rsa_encrypt:{ [data; pub_key]                       }
.tls_crypto.rsa_decrypt:{ [data; prv_key]                       }
.tls_crypto.aes_encrypt:{ [data; key]                           }
.tls_crypto.aes_decrypt:{ [data; key]                           }
.tls_crypto.init_dh_ctx:{ [local_p_key; remote_p_key]           }
.tls_crypto.randomize_dh_secret:{ [ctx]                         }
.tls_crypto.extract_dh_token:{ [ctx; secret]                    }
.tls_crypto.compose_dh_cipher:{ [ctx; secret; remote_token]     }
.tls_crypto.get_dh_key:{ [cipher]                               }
.tls_crypto.b46enc:{ [to]                                       }
.tls_crypto.b64dec:{ [from]                                     }

.sp.comp.register_component[`tls_crypto;enlist `common;.admin_svc.on_comp_start];
