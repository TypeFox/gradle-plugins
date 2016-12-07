/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.gradle.p2gen

import groovy.lang.Closure
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Action

@Accessors(PUBLIC_GETTER)
class RepositoryDependency {
	
	String repositoryUrl
	
	boolean includeConfigurePhase
	
	boolean includeSource
	
	val List<InstallableUnit> units = newArrayList
	
	def void repositoryUrl(String repositoryUrl) {
		this.repositoryUrl = repositoryUrl
	}
	
	def void includeConfigurePhase(boolean includeConfigurePhase) {
		this.includeConfigurePhase = includeConfigurePhase
	}
	
	def void includeSource(boolean includeSource) {
		this.includeSource = includeSource
	}
	
	def bundle(String id) {
		val result = new Bundle
		result.id(id)
		units += result
		return result
	}
	
	def bundle(Action<InstallableUnit> configure) {
		val result = new Bundle
		configure.execute(result)
		units += result
		return result
	}
	
	def bundle(Closure<InstallableUnit> configure) {
		val result = new Bundle
		configure.delegate = result
		configure.resolveStrategy = Closure.DELEGATE_FIRST
		configure.call()
		units += result
		return result
	}
	
	def feature(String id) {
		val result = new Feature
		result.id(id)
		units += result
		return result
	}
	
	def feature(Action<InstallableUnit> configure) {
		val result = new Feature
		configure.execute(result)
		units += result
		return result
	}
	
	def feature(Closure<InstallableUnit> configure) {
		val result = new Feature
		configure.delegate = result
		configure.resolveStrategy = Closure.DELEGATE_FIRST
		configure.call()
		units += result
		return result
	}
	
}
