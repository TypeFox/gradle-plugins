/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.p2gen

import org.eclipse.xtend.lib.annotations.Accessors

@Accessors(PUBLIC_GETTER)
class Bundle {
	
	String id
	
	String version
	
	def void id(String id) {
		this.id = id
	}
	
	def void version(String version) {
		this.version = version
	}
	
}