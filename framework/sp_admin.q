/ This service wil expose functions to be called by SP_ADMIN web svc. 
/ Should have functions to validate a user and register a device

/ u_ - user id
validate_user:{ [u_] : u_ in exec users from .sp.admin.users };


/id_ - device id
/m_ - manufacturer
/p_ - pub key
/os_ - android/ios/any operating system
register_device:{ [id_; m_; p_; os_] :.sp.admin.rd[id_; m_; p_; os_ };



