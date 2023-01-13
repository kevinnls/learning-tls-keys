dummy:
	$(error 'specify a target')

dir = ./priv.d/
CAkeyfile = $(dir)/CA.pem
CAcertfile = $(dir)/CA.crt
CAconffile = CA.cnf
CApassfile = CA-pass.cnf
pkeyfile = $(dir)/$(domain).pem
csrfile = $(dir)/$(domain).csr
certfile = $(dir)/$(domain).crt

CAVerify:
	openssl x509 -text -noout -in $(CAcertfile) | less
CAKey: $(CAkeyfile)
CACert: $(CAcertfile)

$(CAkeyfile):
	openssl genpkey \
		-out $(CAkeyfile) \
		-algorithm EC \
		-aes256 -pass file:$(CApassfile) \
		-pkeyopt ec_paramgen_curve:P-384 \
		-pkeyopt ec_param_enc:named_curve
$(CAcertfile): $(CAkeyfile)
	openssl req -x509 \
		-days 365 \
		-sha512 \
		-config $(CAconffile) \
		-passin file:$(CApassfile) \
		-key $(CAkeyfile) \
		-out $(CAcertfile)

pkey: $(pkeyfile)
$(pkeyfile):
	$(call checkvariable,domain)
	openssl genpkey \
		-out $(pkeyfile) \
		-algorithm EC \
		-pkeyopt ec_paramgen_curve:P-384 \
		-pkeyopt ec_param_enc:named_curve

csr: $(csrfile)
$(csrfile): $(pkeyfile)
	$(call checkvariable,domain)
	openssl req \
		-key $(pkeyfile) \
		-sha256 \
		-new -out $(csrfile)

sign: $(CAcert) $(csrfile)
	$(call checkvariable,domain)
	openssl x509 \
		-key $(pkeyfile) -in $(csrfile) \
		-CAKey $(CAkeyfile) -CACert $(CAcertfile) \
		-days 365 

checkvariable = \
		$(if $(value $1),,\
		$(error variable `$1` is required))
cleanup:
	rm $(dir)/*
