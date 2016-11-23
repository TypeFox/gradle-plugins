/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.p2gen

import groovy.lang.Closure
import java.nio.charset.Charset
import java.util.List
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors(PUBLIC_GETTER)
class P2GenPluginExtension {
	
	Charset charset = Charset.forName('UTF8')
	
	String genPath = 'releng'
	
	String localMavenRepo = 'build/maven-repository'
	
	String localP2Repo = 'build/p2-repository'
	
	String tychoVersion = '0.25.0'
	
	boolean includeDependencies
	
	val List<TargetRepository> targetRepositories = newArrayList
	
	val Set<String> excludes = newHashSet
	
	def void charset(Charset charset) {
		this.charset = charset
	}
	
	def void genPath(String genPath) {
		this.genPath = genPath
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
	
	def void includeDependencies(boolean includeDependencies) {
		this.includeDependencies = includeDependencies
	}
	
	def targetRepository(Closure<TargetRepository> configure) {
		val result = new TargetRepository
		configure.delegate = result
		configure.resolveStrategy = Closure.DELEGATE_FIRST
		configure.call()
		targetRepositories += result
		return result
	}
	
	def void exclude(String module) {
		excludes += module
	}
	
}