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
			doLast[
				val p2BuildDir = new File(rootDir, p2gen.p2BuildPath)
				p2BuildDir.mkdirs()
				Files.write(generatePomXml, new File(p2BuildDir, 'pom.xml'), p2gen.charset)
				Files.write(generateCategoryXml, new File(p2BuildDir, 'category.xml'), p2gen.charset)
			]
		]
	}
	
	def private generatePomXml() '''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
			<modelVersion>4.0.0</modelVersion>
		
			<properties>
				<tycho-version>«p2gen.tychoVersion»</tycho-version>
			</properties>
		
			<groupId>«group»</groupId>
			<artifactId>«name».p2-repository</artifactId>
			<version>«version»</version>
			<packaging>eclipse-repository</packaging>
		
			<repositories>
				<repository>
					<id>local-gradle-result</id>
					<url>file:«mavenRepoPath»</url>
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
				«FOR subproject : subprojects»
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
				«FOR dependency : dependencies»
					<dependency>
						<groupId>«dependency.group»</groupId>
						<artifactId>«dependency.name»</artifactId>
						<version>«dependency.version»</version>
					</dependency>
				«ENDFOR»
			</dependencies>
		
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
										<copy todir="«p2RepoPath»">
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
	
	def private getMavenRepoPath() {
		'''${basedir}«Strings.repeat('/..', p2gen.p2BuildPath.split('/').filter[!empty].size)»/«p2gen.localMavenRepo»'''
	}
	
	def private getP2RepoPath() {
		'''${basedir}«Strings.repeat('/..', p2gen.p2BuildPath.split('/').filter[!empty].size)»/«p2gen.localP2Repo»'''
	}
	
	def private getDependencies() {
		val Set<Dependency> dependencies = newLinkedHashSet
		for (subproject : subprojects) {
			dependencies += subproject.configurations.getByName('compile').allDependencies.filter[ d |
				!subprojects.exists[p | p.group == d.group && p.name == d.name]
			]
		}
		return dependencies
	}
	
	def private generateCategoryXml() '''
		<?xml version="1.0" encoding="UTF-8"?>
		<site>
			«FOR subproject : subprojects»
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
	
}