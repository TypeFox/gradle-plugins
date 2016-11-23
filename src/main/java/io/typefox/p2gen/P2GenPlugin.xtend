/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.p2gen

import com.google.common.base.Strings
import com.google.common.io.Files
import java.io.File
import java.util.Set
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.Dependency

class P2GenPlugin implements Plugin<Project> {
	
	public static val EXTENSION_NAME = 'p2gen'
	
	extension Project project
	P2GenPluginExtension p2gen
	
	override apply(Project project) {
		this.project = project
		this.p2gen = project.extensions.create(EXTENSION_NAME, P2GenPluginExtension)
		project.task('generateP2Build') => [
			group = 'Build Setup'
			description = 'Generates a Tycho build to assemble a P2 repository.'
			
			doLast [
				val genDir = new File(rootDir, p2gen.genPath)
				genDir.mkdirs()
				Files.write(generateParentPom, new File(genDir, 'pom.xml'), p2gen.charset)
				
				val p2BuildDir = new File(genDir, 'p2')
				p2BuildDir.mkdir()
				Files.write(generateP2Pom, new File(p2BuildDir, 'pom.xml'), p2gen.charset)
				Files.write(generateCategoryXml, new File(p2BuildDir, 'category.xml'), p2gen.charset)
				
				if (!p2gen.targetRepositories.empty) {
					val targetBuildDir = new File(genDir, 'releng-target')
					targetBuildDir.mkdir()
					Files.write(generateTargetPom, new File(targetBuildDir, 'pom.xml'), p2gen.charset)
					Files.write(generateTargetFile, new File(targetBuildDir, project.name + '.target.target'), p2gen.charset)
				}
			]
		]
	}
	
	def private getFilteredSubprojects() {
		project.subprojects.filter[!p2gen.excludes.contains(name)]
	}
	
	def private generateParentPom() '''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
			<modelVersion>4.0.0</modelVersion>
		
			<groupId>«group»</groupId>
			<artifactId>«name».releng</artifactId>
			<version>«version»</version>
			<packaging>pom</packaging>
		
			<properties>
				<tycho-version>«p2gen.tychoVersion»</tycho-version>
				<root-dir>${basedir}«Strings.repeat('/..', p2gen.genPath.split('/').filter[!empty].size)»</root-dir>
			</properties>
		
			<repositories>
				<repository>
					<id>local-gradle-result</id>
					<url>file:${root-dir}/«p2gen.localMavenRepo»</url>
				</repository>
				<repository>
					<snapshots>
						<enabled>false</enabled>
					</snapshots>
					<id>jcenter</id>
					<url>http://jcenter.bintray.com</url>
				</repository>
			</repositories>
		
			<dependencies>
				«FOR subproject : filteredSubprojects»
					<dependency>
						<groupId>«subproject.group»</groupId>
						<artifactId>«subproject.name»</artifactId>
						<version>«subproject.version»</version>
					</dependency>
					<dependency>
						<groupId>«subproject.group»</groupId>
						<artifactId>«subproject.name»</artifactId>
						<version>«subproject.version»</version>
						<classifier>sources</classifier>
					</dependency>
				«ENDFOR»
				«IF p2gen.includeDependencies»
					«FOR dependency : allDependencies»
						<dependency>
							<groupId>«dependency.group»</groupId>
							<artifactId>«dependency.name»</artifactId>
							<version>«dependency.version»</version>
						</dependency>
					«ENDFOR»
				«ENDIF»
			</dependencies>

			<modules>
				«IF !p2gen.targetRepositories.empty»
					<module>releng-target</module>
				«ENDIF»
				<module>p2</module>
			</modules>
		
			<build>
				<plugins>
					<plugin>
						<groupId>org.eclipse.tycho</groupId>
						<artifactId>tycho-maven-plugin</artifactId>
						<version>${tycho-version}</version>
						<extensions>true</extensions>
					</plugin>
					<plugin>
						<groupId>org.eclipse.tycho</groupId>
						<artifactId>target-platform-configuration</artifactId>
						<version>${tycho-version}</version>
						<configuration>
							<pomDependencies>consider</pomDependencies>
							«IF !p2gen.targetRepositories.empty»
								<target>
									<artifact>
										<groupId>«group»</groupId>
										<artifactId>«name».target</artifactId>
										<version>«version»</version>
									</artifact>
								</target>
							«ENDIF»
							<environments>
								<environment>
									<os>macosx</os>
									<ws>cocoa</ws>
									<arch>x86_64</arch>
								</environment>
								<environment>
									<os>win32</os>
									<ws>win32</ws>
									<arch>x86_64</arch>
								</environment>
								<environment>
									<os>linux</os>
									<ws>gtk</ws>
									<arch>x86_64</arch>
								</environment>
							</environments>
						</configuration>
					</plugin>
				</plugins>
			</build>
		</project>
	'''
	
	def private generateP2Pom() '''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
			<modelVersion>4.0.0</modelVersion>
		
			<artifactId>«name».p2-repository</artifactId>
			<packaging>eclipse-repository</packaging>
		
			<parent>
				<groupId>«group»</groupId>
				<artifactId>«name».releng</artifactId>
				<version>«version»</version>
				<relativePath>..</relativePath>
			</parent>
		
			<properties>
				<tycho-version>«p2gen.tychoVersion»</tycho-version>
				<root-dir>${basedir}/..«Strings.repeat('/..', p2gen.genPath.split('/').filter[!empty].size)»</root-dir>
			</properties>
		
			<build>
				<plugins>
					<plugin>
						<groupId>org.eclipse.tycho</groupId>
						<artifactId>tycho-p2-repository-plugin</artifactId>
						<version>${tycho-version}</version>
						<executions>
							<execution>
								<phase>package</phase>
								<goals>
									<goal>assemble-repository</goal>
								</goals>
							</execution>
						</executions>
					</plugin>
					<plugin>
						<groupId>org.apache.maven.plugins</groupId>
						<artifactId>maven-antrun-plugin</artifactId>
						<version>1.1</version>
						<executions>
							<execution>
								<phase>install</phase>
								<goals>
									<goal>run</goal>
								</goals>
								<configuration>
									<tasks>
										<copy todir="${root-dir}/«p2gen.localP2Repo»">
											<fileset dir="${basedir}/target/repository/" />
										</copy>
									</tasks>
								</configuration>
							</execution>
						</executions>
					</plugin>
				</plugins>
			</build>
		</project>
	'''
	
	def private getAllDependencies() {
		val Set<Dependency> dependencies = newLinkedHashSet
		for (subproject : filteredSubprojects) {
			dependencies += subproject.configurations.getByName('compile').allDependencies.filter[ d |
				!subprojects.exists[p | p.group == d.group && p.name == d.name]
			]
		}
		return dependencies
	}
	
	def private generateCategoryXml() '''
		<?xml version="1.0" encoding="UTF-8"?>
		<site>
			«FOR subproject : filteredSubprojects»
				<bundle id="«subproject.name»" version="«subproject.version.withoutQualifier».qualifier">
					<category name="«name»"/>
				</bundle>
				<bundle id="«subproject.name».source" version="«subproject.version.withoutQualifier».qualifier">
					<category name="«name»"/>
				</bundle>
			«ENDFOR»
		   <category-def name="«name»" label="«name.toFirstUpper»"/>
		</site>
	'''
	
	def private withoutQualifier(Object version) {
		val versionString = version.toString
		if (versionString.endsWith('-SNAPSHOT'))
			return versionString.substring(0, versionString.length - '-SNAPSHOT'.length)
		val segments = versionString.split('\\.')
		if (segments.length == 4)
			return versionString.substring(0, versionString.lastIndexOf('.'))
		else
			return versionString
	}
	
	def private generateTargetPom() '''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
			<modelVersion>4.0.0</modelVersion>
		
			<artifactId>«name».target</artifactId>
			<packaging>eclipse-target-definition</packaging>
		
			<parent>
				<groupId>«group»</groupId>
				<artifactId>«name».releng</artifactId>
				<version>«version»</version>
				<relativePath>..</relativePath>
			</parent>
		</project>
	'''
	
	def private generateTargetFile() '''
		<?xml version="1.0" encoding="UTF-8"?>
		<?pde version="3.8"?>
		<target name="org.eclipse.xtext.helios.target" sequenceNumber="0">
			<locations>
				«FOR targetRepo : p2gen.targetRepositories»
					<location includeAllPlatforms="false" includeConfigurePhase="«targetRepo.includeConfigurePhase»" includeMode="planner" includeSource="«targetRepo.includeSource»" type="InstallableUnit">
						«FOR unit : targetRepo.units»
							<unit id="«unit»" version="0.0.0"/>
						«ENDFOR»
						<repository location="«targetRepo.location»"/>
					</location>
				«ENDFOR»
			</locations>
		</target>
	'''
	
}