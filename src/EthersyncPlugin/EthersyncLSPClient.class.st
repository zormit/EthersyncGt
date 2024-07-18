Class {
	#name : #EthersyncLSPClient,
	#superclass : #GtLanguageServerProtocolStdioClient,
	#category : #EthersyncPlugin
}

{ #category : #accessing }
EthersyncLSPClient class >> create [
^self new
			program: '/Users/mn/.local/bin/ethersync';
			arguments: #('client');
			defaultLanguageType: '';
			start;
			yourself.
]

{ #category : #accessing }
EthersyncLSPClient >> open: uri [
self sendNotification: 'open' with: {'uri'->uri}.
]
