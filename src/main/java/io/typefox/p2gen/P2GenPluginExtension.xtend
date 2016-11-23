package io.typefox.p2gen

import java.nio.charset.Charset
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors(PUBLIC_GETTER)
class P2GenPluginExtension {
	
	Charset charset = Charset.forName('UTF8')
	
	String p2BuildPath = 'releng/p2'
	
	String localMavenRepo = 'build/maven-repository'
	
	String localP2Repo = 'build/p2-repository'
	
	String tychoVersion = '0.25.0'
	
	def void charset(Charset charset) {
		this.charset = charset
	}
	
	def void p2BuildPath(String p2BuildPath) {
		this.p2BuildPath = p2BuildPath
	}
	
	def void localMavenRepo(String localMavenRepo) {
		this.localMavenRepo = localMavenRepo
	}
	
	def void localP2Repo(String localP2Repo) {
		this.localP2Repo = localP2Repo
	}
	
	def void tychoVersion(String tychoVersion) {
		this.tychoVersion = tychoVersion
	}
	
}