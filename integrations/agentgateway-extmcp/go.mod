module github.com/sebastienrousseau/scout-reporting/integrations/agentgateway-extmcp

go 1.26.8

require (
	github.com/sebastienrousseau/scout-reporting v0.0.5
	google.golang.org/grpc v1.78.0
	google.golang.org/protobuf v1.36.10
)

require (
	golang.org/x/net v0.55.0 // indirect
	golang.org/x/sys v0.45.0 // indirect
	golang.org/x/text v0.37.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251029180050-ab9386a59fda // indirect
)

// The verifier is the enclosing repository's, always at the same commit:
// this module is a program built from a checkout, not a library anyone
// imports, so the replace is the mechanism and the version above names the
// release it tracks.
replace github.com/sebastienrousseau/scout-reporting => ../..
