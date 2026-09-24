module github.com/sebastienrousseau/scout-reporting/integrations/agentgateway-extmcp

go 1.26.8

require (
	github.com/sebastienrousseau/scout-reporting v0.0.5
	google.golang.org/grpc v1.83.2
	google.golang.org/protobuf v1.36.11
)

require (
	golang.org/x/net v0.58.0 // indirect
	golang.org/x/sys v0.47.0 // indirect
	golang.org/x/text v0.41.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20260526163538-3dc84a4a5aaa // indirect
)

// The verifier is the enclosing repository's, always at the same commit:
// this module is a program built from a checkout, not a library anyone
// imports, so the replace is the mechanism and the version above names the
// release it tracks.
replace github.com/sebastienrousseau/scout-reporting => ../..
