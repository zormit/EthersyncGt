"
I am inspired/copied from TCPSocketEchoTest.

My author isn't sure yet, whether he'll be able to keep the test-case structure.
"
Class {
	#name : #EthersyncSocketTest,
	#superclass : #TestCase,
	#instVars : [
		'socketFile'
	],
	#category : #EthersyncGt
}

{ #category : #accessing }
EthersyncSocketTest class >> defaultSocketFile [

	^ FileLocator root / 'tmp' / 'etherpharo'.
]

{ #category : #testing }
EthersyncSocketTest >> clientSend: message [
	"Send message to the local TCP echo service and return the result"

	| socket |
	socket := Socket newTCP.
	^ [
		socket connectTo: self localhost port: self port.
		socket sendData: message.
		socket receiveData ]
			ensure: [ socket closeAndDestroy ]
]

{ #category : #private }
EthersyncSocketTest >> handleClient: clientSocket [
	| result stream |
	[ stream := ZnNetworkingUtils socketStreamOn: clientSocket.

	[ [ stream
		nextPutAll: 'Hello from SMALLtok\n';
		flush.
	result := stream upToEnd.	"Give us all data until the socket is closed."
	Transcript
		show: result;
		cr ] ensure: [ stream close ] ]
		on: ConnectionTimedOut
		do: [ :ex | 
			Transcript
				show: ex asString;
				cr.
			ex resume ] ] ensure: [ clientSocket closeAndDestroy ]
]

{ #category : #accessing }
EthersyncSocketTest >> localhost [
	"Return the host address where the TCP echo service runs, the local host address"

	^ NetNameResolver localHostAddress
]

{ #category : #testing }
EthersyncSocketTest >> runServer [
	"Run and return a local TCP echo server"

	^ self withIPCServer: [ :process | process ]
]

{ #category : #accessing }
EthersyncSocketTest >> socketAddress [
	"Return the socketAddress where the service runs"

	| socketAddress |
	self socketFile exists ifFalse: [ self socketFile ensureCreateFile ].
	socketAddress := NetNameResolver addressForSocketPath: self socketFile fullName.
	self socketFile delete.
	^ socketAddress
]

{ #category : #accessing }
EthersyncSocketTest >> socketFile [
	socketFile ifNil: [ ^ self class defaultSocketFile ].
	^ socketFile
]

{ #category : #testing }
EthersyncSocketTest >> testEcho [
	| socket message result |
	socket := Socket newTCP.
	[
		self withIPCServer: [ :process |
			message := 'Testing ', 99 atRandom asString.
			socket connectTo: self localhost port: self port.
			socket sendData: message.
			result := socket receiveData.
			self assert: result equals: message ]
	] ensure: [ socket closeAndDestroy ].
	"At this point the server is still running, ask it to kill itself"
	self clientSend: #quit
]

{ #category : #private }
EthersyncSocketTest >> withIPCServer: block [
	"Run a local TCP echo server on localhost:port and execute block.
	Optionally pass the new process to block. When quit is received, stop the server"

	| serverSocket serverLoop process |
	serverSocket := Socket newIPC.
	serverSocket primSocket: serverSocket socketHandle bindTo: self socketAddress.
	serverSocket primSocket: serverSocket socketHandle listenWithBacklog: 10.
	serverLoop := true.
	process := [ [ [ serverLoop ]
			whileTrue: [ (serverSocket waitForAcceptFor: 60)
					ifNotNil: [ :clientSocket | 
						[ self handleClient: clientSocket ]
							forkAt: Processor lowIOPriority
							named: 'Ethersync Editor connection' ] ] ]
			ensure: [ serverSocket closeAndDestroy ] ]
			forkAt: Processor highIOPriority
			named: 'Ethersync IPC server'.
	^ block cull: process
]
