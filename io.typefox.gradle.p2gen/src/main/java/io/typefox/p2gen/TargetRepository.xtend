/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.p2gen

import groovy.lang.Closure
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Action

@Accessors(PUBLIC_GETTER)
class TargetRepository {
	
	String location
	
	boolean includeConfigurePhase
	
	boolean includeSource
	
	val List<Bundle> units = newArrayList
	
	def void location(String location) {
		this.location = location
	}
	
	def void includeConfigurePhase(boolean includeConfigurePhase) {
		this.includeConfigurePhase = includeConfigurePhase
	}
	
	def void includeSource(boolean includeSource) {
		this.includeSource = includeSource
	}
	
	def unit(String id) {
		val result = new Bundle
		result.id(id)
		units += result
		return result
	}
	
	def unit(Action<Bundle> configure) {
		val result = new Bundle
		configure.execute(result)
		units += result
		return result
	}
	
	def unit(Closure<Bundle> configure) {
		val result = new Bundle
		configure.delegate = result
		configure.resolveStrategy = Closure.DELEGATE_FIRST
		configure.call()
		units += result
		return result
	}
	
}