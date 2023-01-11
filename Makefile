pkeyfile ?= keys.d/x25519.key.pem
dummy:
	$(error 'specify a target')

private_key: $(pkeyfile)

$(pkeyfile):
	openssl genpkey \
		-algorithm X25519 \
		-out $(pkeyfile)
csr: $(pkeyfile)
	$(call checkvariable,domain)
	openssl req \
		-key $(pkeyfile) \
		-sha256 \
		-new -out $(domain).csr

checkvariable = \
		$(if $(value $1),,\
		$(error variable `$1` is required))
