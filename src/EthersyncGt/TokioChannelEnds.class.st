Class {
	#name : #TokioChannelEnds,
	#superclass : #Object,
	#instVars : [
		'ast'
	],
	#category : #EthersyncGt
}

{ #category : #accessing }
TokioChannelEnds class >> fromSource: aFileReference [
	^ self new
		ast: (aFileReference smaCCParseUsing: RustParser);
		yourself
]

{ #category : #accessing }
TokioChannelEnds class >> structNode: node owns: senderIdentifier [
	^ node fields
		anySatisfy: [ :field | 
			field value isNil
				ifTrue: [ field name value = senderIdentifier ]
				ifFalse: [ field value class = RustPathExpressionNode
						and: [ (field value names collect: #value) asArray = {senderIdentifier} ] ] ]
]

{ #category : #accessing }
TokioChannelEnds >> ast [
	^ ast
]

{ #category : #accessing }
TokioChannelEnds >> ast: anAST [
	ast:= anAST
]

{ #category : #accessing }
TokioChannelEnds >> drawEverything [
	| associations |
	associations := self mapChannelEnds.
	^ self drawEverything: associations
]

{ #category : #accessing }
TokioChannelEnds >> drawEverything: senderReceiverAssociations [
	| aMondrian |
	aMondrian := GtMondrian new.
	aMondrian nodes
		stencil: [ :each | BlTextElement text: each names first value asRopedText ];
		with: (senderReceiverAssociations
				collect: [ :each | 
					{each key.
						each value} ]) flatten.
	aMondrian edges
		stencil: [ :x | 
			BlLineElement new
				border: (BlBorder paint: Color blue width: 1);
				toHead: (BlArrowheadSimpleArrow new
						arrowLengthFraction: 2;
						background: (Color blue alpha: 0.5);
						border: (BlBorder paint: (Color blue alpha: 0.5) width: 2);
						zIndex: -1) ];
		connect: senderReceiverAssociations
			from: #key
			to: #value.
	aMondrian layout tree
		levelDistance: 150;
		nodeDistance: 2;
		treesDistance: 2.
	^ aMondrian
]

{ #category : #accessing }
TokioChannelEnds >> mapChannelEnds [
	| definitions identifiers |
	definitions := self mpscChannelDefinitions.
	identifiers := self txrxIdentifiers: definitions.
	^ identifiers
		collect: [ :each | 
			(self senderOwningStruct: ((each at: 'sender') name value))
				-> (self receiverOwningStruct: ((each at: 'receiver') name value)) ]
]

{ #category : #accessing }
TokioChannelEnds >> mpscChannelDefinitions [
	" Returns the RustLetStatementNodes that define a channel. Expected form: let (tx, rx) = mpsc::channel(size)"

	| mpscChannelNodes |
	mpscChannelNodes := self ast // RustLetStatementNode value
			// RustPathExpressionNode
			select: [ :node | (node names collect: #value) asArray = #('mpsc' 'channel') ].
	^ mpscChannelNodes collect: [ :each | each parent parent ]
]

{ #category : #accessing }
TokioChannelEnds >> receiverOwningStruct: receiverIdentifier [
	" Heuristics: the receiver always gets passed to a struct via its constructor. Returns this struct or nil. "

	| usedInConstructors |
	usedInConstructors := self ast // RustPathExpressionNode
			select: [ :each | 
				(each names collect: #value) asArray last = 'new'
					and: [ each parent args
							anySatisfy: [ :arg | 
								arg class = RustPathExpressionNode
									and: [ (arg names collect: #value) asArray = {receiverIdentifier} ] ] ] ].
	^ usedInConstructors isEmpty ifTrue: nil ifFalse: [ usedInConstructors anyOne ]
]

{ #category : #accessing }
TokioChannelEnds >> senderOwningStruct: senderIdentifier [
	" Heuristics: the sender always gets stored in a Self of a struct. Returns this struct or nil. "

	| theSelf theType |
	theSelf := self ast // RustPathExpressionNode
			select: [ :each | 
				(each names collect: #value) asArray = #('Self')
					and: [ self class structNode: each parent owns: senderIdentifier ] ].

	theSelf isEmpty ifTrue: [ ^ nil ].
	theType := (theSelf anyOne \\ RustImplementationNode) anyOne types first.
	^ theType
]

{ #category : #accessing }
TokioChannelEnds >> txrxIdentifiers: someChannelDefinitions [
	" unpacking tuple on the left side to a sender / receiver mapping. "

	^ someChannelDefinitions
		collect: [ :node | 
			| identifierTuple |
			identifierTuple := node patterns anyOne patterns.
			Dictionary
				newFrom: {'sender' -> identifierTuple first.
						'receiver' -> identifierTuple second} ]
]
