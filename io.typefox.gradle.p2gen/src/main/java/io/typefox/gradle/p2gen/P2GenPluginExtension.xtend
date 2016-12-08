/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.gradle.p2gen

import groovy.lang.Closure
import java.nio.charset.Charset
import java.util.List
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Action

@Accessors(PUBLIC_GETTER)
class P2GenPluginExtension {
	
	Charset charset = Charset.forName('UTF8')
	
	String genPath = 'releng'
	
	String localMavenRepo = 'build/maven-repository'
	
	String localP2Repo = 'build/p2-repository'
	
	String tychoVersion = '0.26.0'
	
	val List<String> features = newArrayList
	
	val List<RepositoryDependency> dependencies = newArrayList
	
	val Set<String> excludes = newHashSet
	
	val List<InstallableUnit> additionalUnits = newArrayList
	
	boolean zipRepository
	
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
	
	def void feature(String feature) {
		features += feature
	}
	
	def dependencies(Action<RepositoryDependency> configure) {
		val result = new RepositoryDependency
		configure.execute(result)
		dependencies += result
		return result
	}
	
	def dependencies(Closure<RepositoryDependency> configure) {
		val result = new RepositoryDependency
		configure.delegate = result
		configure.resolveStrategy = Closure.DELEGATE_FIRST
		configure.call()
		dependencies += result
		return result
	}
	
	def void exclude(String module) {
		excludes += module
	}
	
	def additionalBundle(String id) {
		val result = new Bundle
		result.id(id)
		additionalUnits += result
		return result
	}
	
	def additionalBundle(Action<InstallableUnit> configure) {
		val result = new Bundle
		configure.execute(result)
		additionalUnits += result
		return result
	}
	
	def additionalBundle(Closure<InstallableUnit> configure) {
		val result = new Bundle
		configure.delegate = result
		configure.resolveStrategy = Closure.DELEGATE_FIRST
		configure.call()
		additionalUnits += result
		return result
	}
	
	def additionalFeature(String id) {
		val result = new Feature
		result.id(id)
		additionalUnits += result
		return result
	}
	
	def additionalFeature(Action<InstallableUnit> configure) {
		val result = new Feature
		configure.execute(result)
		additionalUnits += result
		return result
	}
	
	def additionalFeature(Closure<InstallableUnit> configure) {
		val result = new Feature
		configure.delegate = result
		configure.resolveStrategy = Closure.DELEGATE_FIRST
		configure.call()
		additionalUnits += result
		return result
	}
	
	def void zipRepository(boolean zipRepository) {
		this.zipRepository = zipRepository
	}
	
}
