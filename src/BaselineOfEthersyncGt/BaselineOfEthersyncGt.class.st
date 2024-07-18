Class {
	#name : #BaselineOfEthersyncGt,
	#superclass : #BaselineOf,
	#category : #BaselineOfEthersyncGt
}

{ #category : #accessing }
BaselineOfEthersyncGt class >> gtDependencyAnalysisPreloadedBaselines [
	^ super gtDependencyAnalysisPreloadedBaselines copyWith: BaselineOfGToolkit
]

{ #category : #loading }
BaselineOfEthersyncGt class >> loadLepiter [
	IceRepository registry  
		detect: [ :aRepository |
			aRepository name = 'EthersyncGt' ]
		ifFound: [ :aRepository | 
			| defaultDatabase currentProperties |
			defaultDatabase := LeDatabasesRegistry defaultLogicalDatabase.
			currentProperties := defaultDatabase properties.
			currentProperties addRegisteredDirectory: aRepository repositoryDirectory / 'lepiter'.
			defaultDatabase reload ]
		ifNone: [
			self inform: 'Repository not found.' ]
]

{ #category : #baseline }
BaselineOfEthersyncGt >> baseline: spec [
	<baseline>
	^ spec
		for: #common
		do: [ spec
				package: 'EthersyncGt';
				package: 'EthersyncPlugin' ]
]
