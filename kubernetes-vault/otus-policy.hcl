path "/otus/data/cred" {
  capabilities = ["read","list"]
}

path "/otus/metadata/cred" {
    capabilities = ["read", "list"]
}

path "auth/token/renew-self" {
    capabilities = ["update"]
}
