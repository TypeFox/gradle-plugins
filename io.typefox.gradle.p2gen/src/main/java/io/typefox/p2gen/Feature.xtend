/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.p2gen

import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors
class Feature {
	
	String path
	
	String id
	
	String version
	
	val Set<String> plugins = newHashSet
	
}