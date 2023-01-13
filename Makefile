dummy:
	$(error 'specify a target')

dir = ./priv.d

CAkeyfile = $(dir)/CA.pem
CAcertfile = $(dir)/CA.crt
CAconffile = CA.cnf
CApassfile = CA-pass.cnf

pkeyfile = $(dir)/$(domain).pem
csrfile = $(dir)/$(domain).csr
certfile = $(dir)/$(domain).crt
domainconffile = domain.cnf

ifdef san
san_ext = -addext 'subjectAltName=$(san)'
endif

show-CA:
	openssl x509 -text -noout -in $(CAcertfile) | less

CAKey: $(CAkeyfile)
$(CAkeyfile):
	openssl genpkey \
		-out $(CAkeyfile) \
		-algorithm EC \
		-aes256 -pass file:$(CApassfile) \
		-pkeyopt ec_paramgen_curve:P-384 \
		-pkeyopt ec_param_enc:named_curve

CACert: $(CAcertfile)
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
$(csrfile): export domain=$(domain)
$(csrfile): $(pkeyfile)
	$(call checkvariable,domain)
	openssl req \
		-key $(pkeyfile) \
		-sha512 \
		-config $(domainconffile) \
		$(san_ext) \
		-new -out $(csrfile)

show-csr:
	$(call checkvariable,domain)
	openssl req -text -noout -in $(csrfile) | less

sign: $(CAcert) $(csrfile)
	$(call checkvariable,domain)
	openssl x509 -req \
		-in $(csrfile) \
		-CAkey $(CAkeyfile) -CA $(CAcertfile) \
		-passin file:$(CApassfile) \
		-copy_extensions copy -ext subjectAltName \
		-days 365 \
		-sha512 \
		-out $(certfile)
show:
	$(call checkvariable,domain)
	openssl x509 -noout -text -in $(certfile) | less

checkvariable = \
		$(if $(value $1),,\
		$(error variable `$1` is required))
cleanup:
	rm $(dir)/*

www:
	http-server -S -K $(pkeyfile) -C $(certfile)
