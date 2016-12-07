package io.typefox.gradle.p2gen

import org.eclipse.xtend.lib.annotations.Accessors

@Accessors(PUBLIC_GETTER)
abstract class InstallableUnit {
	
	String id
	
	String version
	
	def void id(String id) {
		this.id = id
	}
	
	def void version(String version) {
		this.version = version
	}
	
}