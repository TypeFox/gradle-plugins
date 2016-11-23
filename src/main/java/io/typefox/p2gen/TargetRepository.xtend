/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.p2gen

import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors(PUBLIC_GETTER)
class TargetRepository {
	
	String location
	
	boolean includeConfigurePhase
	
	boolean includeSource
	
	val List<String> units = newArrayList
	
	def void location(String location) {
		this.location = location
	}
	
	def void includeConfigurePhase(boolean includeConfigurePhase) {
		this.includeConfigurePhase = includeConfigurePhase
	}
	
	def void includeSource(boolean includeSource) {
		this.includeSource = includeSource
	}
	
	def void unit(String unit) {
		this.units += unit
	}
	
}