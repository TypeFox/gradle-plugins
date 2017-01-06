/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.gradle.p2gen

import com.google.common.base.Strings
import com.google.common.io.Files
import groovy.util.XmlSlurper
import groovy.util.slurpersupport.GPathResult
import java.io.File
import java.io.FilenameFilter
import java.util.List
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.repositories.MavenArtifactRepository

class P2GenPlugin implements Plugin<Project> {
	
	public static val EXTENSION_NAME = 'p2gen'
	
	extension Project project
	P2GenPluginExtension p2gen
	List<Feature> features = newArrayList
	
	override apply(Project project) {
		this.project = project
		this.p2gen = project.extensions.create(EXTENSION_NAME, P2GenPluginExtension)
		project.tasks.create('generateP2Build') [
			group = 'Build Setup'
			description = 'Generates a Tycho build to assemble a P2 repository.'
			
			doLast [
				loadFeatures()
				val genDir = new File(rootDir, p2gen.genPath)
				genDir.mkdirs()
				Files.write(generateParentPom, new File(genDir, 'pom.xml'), p2gen.charset)
				
				val p2BuildDir = new File(genDir, 'p2')
				p2BuildDir.mkdir()
				Files.write(generateP2Pom, new File(p2BuildDir, 'pom.xml'), p2gen.charset)
				Files.write(generateCategoryXml, new File(p2BuildDir, 'category.xml'), p2gen.charset)
				
				if (!p2gen.dependencies.empty) {
					val targetBuildDir = new File(genDir, 'releng-target')
					targetBuildDir.mkdir()
					Files.write(generateTargetPom, new File(targetBuildDir, 'pom.xml'), p2gen.charset)
					Files.write(generateTargetFile, new File(targetBuildDir, project.name + '.target.target'), p2gen.charset)
				}
				
				for (feature : features) {
					val featureBuildDir = new File(genDir, feature.path)
					featureBuildDir.mkdir()
					Files.write(generateFeaturePom(feature), new File(featureBuildDir, 'pom.xml'), p2gen.charset)
					Files.write(generateFeatureBuildProperties(feature), new File(featureBuildDir, 'build.properties'), p2gen.charset)
				}
			]
		]
	}
	
	def private getFilteredSubprojects() {
		project.subprojects.filter[!p2gen.excludes.contains(name)]
	}
	
	def private getPomVersion() {
		val version = project.version.toString
		if (version.split('\\.').length == 4)
			version.substring(0, version.lastIndexOf('.')) + '-SNAPSHOT'
		else if (!version.endsWith('-SNAPSHOT'))
			version + '-SNAPSHOT'
		else
			version
	}
	
	def private generateParentPom() '''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
			<modelVersion>4.0.0</modelVersion>
		
			<groupId>«group»</groupId>
			<artifactId>«name».releng</artifactId>
			<version>«pomVersion»</version>
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
				«FOR repo : filteredSubprojects.findFirst[plugins.hasPlugin('java')].repositories.filter(MavenArtifactRepository)»
					<repository>
						<id>«repo.name»</id>
						<url>«repo.url»</url>
						«IF repo.name == 'BintrayJCenter'»
							<snapshots>
								<enabled>false</enabled>
							</snapshots>
						«ENDIF»
					</repository>
				«ENDFOR»
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
			</dependencies>

			<modules>
				«IF !p2gen.dependencies.empty»
					<module>releng-target</module>
				«ENDIF»
				<module>p2</module>
				«FOR feature : features»
					<module>«feature.path»</module>
				«ENDFOR»
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
							«IF !p2gen.dependencies.empty»
								<target>
									<artifact>
										<groupId>«group»</groupId>
										<artifactId>«name».target</artifactId>
										<version>«pomVersion»</version>
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
					<plugin>
						<groupId>org.eclipse.tycho</groupId>
						<artifactId>tycho-packaging-plugin</artifactId>
						<version>${tycho-version}</version>
						<configuration>
							<format>«p2gen.qualifierFormat»</format>
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
				<version>«pomVersion»</version>
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
										«IF p2gen.zipRepository»
											<copy
												file="${basedir}/target/«name».p2-repository-«pomVersion».zip"
												tofile="${root-dir}/«p2gen.localP2Repo»/../«name».p2-repository-«version».zip">
											</copy>
										«ENDIF»
									</tasks>
								</configuration>
							</execution>
						</executions>
					</plugin>
				</plugins>
			</build>
		</project>
	'''
	
	def private generateCategoryXml() '''
		<?xml version="1.0" encoding="UTF-8"?>
		<site>
			«FOR feature : features»
				<feature id="«feature.id»" version="«feature.version»">
					<category name="«name»"/>
				</feature>
			«ENDFOR»
			«FOR subproject : filteredSubprojects»
				«IF !features.exists[plugins.contains(subproject.name)]»
					<bundle id="«subproject.name»" version="«subproject.version.withoutQualifier».qualifier">
						<category name="«name»"/>
					</bundle>
				«ENDIF»
				«IF !features.exists[plugins.contains(subproject.name + '.source')]»
					<bundle id="«subproject.name».source" version="«subproject.version.withoutQualifier».qualifier">
						<category name="«name»"/>
					</bundle>
				«ENDIF»
			«ENDFOR»
			«FOR unit : p2gen.additionalUnits»
				«IF unit instanceof Feature»
					<feature«
				ELSE»
					<bundle«
				ENDIF» id="«unit.id»" version="«IF unit.version.nullOrEmpty»0.0.0«ELSE»«unit.version»«ENDIF»"/>
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
				<version>«pomVersion»</version>
				<relativePath>..</relativePath>
			</parent>
		</project>
	'''
	
	def private generateTargetFile() '''
		<?xml version="1.0" encoding="UTF-8"?>
		<?pde version="3.8"?>
		<target name="org.eclipse.xtext.helios.target" sequenceNumber="0">
			<locations>
				«FOR dep : p2gen.dependencies»
					<location includeAllPlatforms="false" includeConfigurePhase="«dep.includeConfigurePhase»" includeMode="planner" includeSource="«dep.includeSource»" type="InstallableUnit">
						<repository location="«dep.repositoryUrl»"/>
						«FOR unit : dep.units»
							<unit id="«unit.id»«IF unit instanceof Feature».feature.group«ENDIF»" version="«
								IF unit.version.nullOrEmpty»0.0.0«ELSE»«unit.version»«ENDIF»"/>
						«ENDFOR»
					</location>
				«ENDFOR»
			</locations>
		</target>
	'''
	
	def private generateFeaturePom(Feature feature) '''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
			<modelVersion>4.0.0</modelVersion>
		
			«IF filteredSubprojects.exists[group == project.group && name == feature.id]»
				<groupId>«group».feature</groupId>
			«ENDIF»
			<artifactId>«feature.id»</artifactId>
			<packaging>eclipse-feature</packaging>
		
			<parent>
				<groupId>«group»</groupId>
				<artifactId>«name».releng</artifactId>
				<version>«pomVersion»</version>
				<relativePath>..</relativePath>
			</parent>
		</project>
	'''
	
	static val FilenameFilter FEATURE_BUILD_FILTER = [ dir, name |
		!name.startsWith('.') && name != 'pom.xml' && (dir.name.endsWith('.license') || name != 'build.properties')
			&& !(new File(dir, name).isDirectory)
	]
	
	def private generateFeatureBuildProperties(Feature feature) '''
		bin.includes = «FOR file : new File('''«rootDir»/«p2gen.genPath»/«feature.path»''').listFiles(FEATURE_BUILD_FILTER).sort
			SEPARATOR ',\\\n               '»«file.name»«ENDFOR»
	'''
	
	def private void loadFeatures() {
		for (featurePath : p2gen.features) {
			val feature = new Feature
			feature.path = featurePath
			try {
				val slurpResult = new XmlSlurper().parse(new File('''«rootDir»/«p2gen.genPath»/«featurePath»/feature.xml'''))
				if (slurpResult.name == 'feature') {
					feature.id(slurpResult.getProperty('@id')?.toString)
					feature.version(slurpResult.getProperty('@version')?.toString)
					val content = slurpResult.children
					for (var i = 0; i < content.size; i++) {
						val elem = content.getAt(i)
						if (elem instanceof GPathResult) {
							if (elem.name == 'plugin') {
								val pluginId = elem.getProperty('@id')?.toString
								if (pluginId !== null)
									feature.plugins += pluginId
							}
						}
					}
				}
			} catch (Exception e) {
				logger.warn('Could not read feature.xml of ' + featurePath, e)
			}
			features += feature
		}
	}
	
}
				