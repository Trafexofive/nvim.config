local M = {}

-- Function to create a directory if it doesn't exist
local function create_dir(path)
    if vim.fn.isdirectory(path) == 0 then
        vim.fn.mkdir(path, "p")
    end
end

-- Function to write content to a file
local function write_file(path, content)
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
    else
        vim.notify("Failed to create file: " .. path, vim.log.levels.ERROR)
    end
end

-- Function to create a basic Minecraft mod project structure
function M.create_mod_project(project_name, mod_type, version)
    local project_path = vim.fn.getcwd() .. "/" .. project_name
    local mod_type = mod_type or "fabric"
    local version = version or "1.20.1"

    -- Create project directory
    create_dir(project_path)

    -- Create standard Minecraft mod directories
    create_dir(project_path .. "/src/main/java")
    create_dir(project_path .. "/src/main/resources")
    create_dir(project_path .. "/gradle/wrapper")

    -- Create the mod metadata file based on mod type
    if mod_type == "fabric" then
        M.create_fabric_mod(project_path, project_name, version)
    elseif mod_type == "forge" then
        M.create_forge_mod(project_path, project_name, version)
    elseif mod_type == "quilt" then
        M.create_quilt_mod(project_path, project_name, version)
    else
        vim.notify("Unsupported mod type: " .. mod_type, vim.log.levels.ERROR)
        return
    end

    -- Create common files
    M.create_gitignore(project_path)
    M.create_readme(project_path, project_name, mod_type, version)

    vim.notify("Minecraft mod project '" .. project_name .. "' created successfully!", vim.log.levels.INFO)
end

-- Function to create Fabric mod structure
function M.create_fabric_mod(project_path, project_name, version)
    -- Create fabric.mod.json
    local fabric_json = [[{
  "schemaVersion": 1,
  "id": "]] .. string.lower(project_name):gsub(" ", "_") .. [[",
  "version": "${version}",
  "name": "]] .. project_name .. [[",
  "description": "A Fabric mod",
  "authors": [
    "Your Name"
  ],
  "contact": {
    "homepage": "https://fabricmc.net/",
    "sources": "https://github.com/YOUR_USERNAME/YOUR_REPOSITORY"
  },
  "license": "CC0-1.0",
  "icon": "assets/modid/icon.png",
  "environment": "*",
  "entrypoints": {
    "main": [
      "]] .. string.gsub(project_name, "%s+", ""):lower() .. [[.Main"
    ]
  },
  "depends": {
    "fabricloader": ">=0.14.0",
    "minecraft": "]] .. version .. [[",
    "java": ">=17",
    "fabric-api": "*"
  },
  "suggests": {
    "another-mod": "*"
  }
}]]

    write_file(project_path .. "/src/main/resources/fabric.mod.json", fabric_json)

    -- Create build.gradle
    local build_gradle = [[plugins {
	id 'fabric-loom' version '1.2-SNAPSHOT'
	id 'java'
}

version = project.mod_version
group = project.maven_group

base {
	archivesName = project.archives_base_name
}

repositories {
	maven {
		name = 'Fabric'
		url = 'https://maven.fabricmc.net/'
	}
	// Add repositories to retrieve artifacts from in here.
	// You should only use this when depending on other mods because
	// Loom adds the essential maven repositories to resolve dependencies.
}

dependencies {
	// To change the versions see the gradle.properties file
	minecraft "com.mojang:minecraft:${project.minecraft_version}"
	mappings "net.fabricmc:yarn:${project.yarn_mappings}:v2"
	modImplementation "net.fabricmc:fabric-loader:${project.loader_version}"

	// Fabric API. This is technically optional, but you probably want it anyway.
	modImplementation "net.fabricmc.fabric-api:fabric-api:${project.fabric_version}"
}

processResources {
	inputs.property "version", project.version

	filesMatching("fabric.mod.json") {
		expand "version": project.version
	}
}

tasks.withType(JavaCompile).configureEach {
	it.options.release = 17
}

java {
	// Loom will automatically attach sourcesJar to a RemapSourcesJar task and to the "build" task
	// if it is present.
	// If you remove this line, sources will not be generated.
	withSourcesJar()

	sourceCompatibility = JavaVersion.VERSION_17
	targetCompatibility = JavaVersion.VERSION_17
}

jar {
	from("LICENSE") {
		rename { "${it}_${project.base.archivesName.get()}"}
	}
}
]]
    write_file(project_path .. "/build.gradle", build_gradle)

    -- Create gradle.properties
    local gradle_properties = [[# Done to increase the memory available to gradle.
org.gradle.jvmargs=-Xmx1G
org.gradle.parallel=true

# Fabric Properties
# check these on https://fabricmc.net/develop
minecraft_version=]] .. version .. [[
yarn_mappings=1.20.1+build.10
loader_version=0.14.21

# Mod Properties
mod_version = 1.0.0
maven_group = com.yourname
archives_base_name = ]] .. project_name:gsub(" ", "_"):lower() .. [[

# Dependencies
fabric_version=0.83.0+1.20.1
]]
    write_file(project_path .. "/gradle.properties", gradle_properties)

    -- Create settings.gradle
    local settings_gradle = [[pluginManagement {
	repositories {
		maven {
			name = 'Fabric'
			url = 'https://maven.fabricmc.net/'
		}
		mavenCentral()
		gradlePluginPortal()
	}
}
]]
    write_file(project_path .. "/settings.gradle", settings_gradle)

    -- Create main Java class
    local main_class_name = string.gsub(project_name, "%s+", ""):lower()
    local main_java = [[package ]]
        .. main_class_name
        .. [[;

import net.fabricmc.api.ModInitializer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Main implements ModInitializer {
	public static final String MOD_ID = "]]
        .. string.lower(project_name):gsub(" ", "_")
        .. [[";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

	@Override
	public void onInitialize() {
		LOGGER.info("Hello Fabric world!");
	}
}
]]
    create_dir(project_path .. "/src/main/java/" .. main_class_name:gsub("%.", "/"))
    write_file(project_path .. "/src/main/java/" .. main_class_name .. "/Main.java", main_java)
end

-- Function to create Forge mod structure
function M.create_forge_mod(project_path, project_name, version)
    -- Create mods.toml
    local mods_toml = [==[# This is an example mods.toml file. It contains the data relating to the loading mods.
# There are several mandatory fields (#mandatory), and many more optional fields (#optional).
# The overall format is standard TOML format.
# Note that there are a couple of special values that will be replaced by the build script:
#     ${file.jarVersion} - Is replaced with the value of the Implementation-Version as read from the jar file's MANIFEST.MF
#     ${mod_version} - Is replaced with the value of the 'version' property defined in gradle.properties

modLoader="javafml" #mandatory
loaderVersion="[47,)" #mandatory This is typically bumped every Minecraft version by Forge. See https://files.minecraftforge.net/
# The license for you mod. This is mandatory metadata and allows for easier comprehension of your redistributive properties.
# Review your options at https://choosealicense.com/. All rights reserved is the default copyright stance, and is thus the default here.
license="All rights reserved"
# A URL to refer people to when problems occur with this mod
#issueTrackerURL="https://change.me.to.your.issue.tracker.example.invalid/" #optional
[[mods]] #mandatory
# The name of the mod
modId="]==] .. string.lower(project_name):gsub(" ", "_") .. [==[" #mandatory
# The version of the mod
version="${file.jarVersion}" #mandatory
# A display name for the mod
displayName="]==] .. project_name .. [==[" #mandatory
# A URL to query for updates for this mod. See the JSON update specification https://docs.minecraftforge.net/en/latest/misc/updatechecker/
#updateJSONURL="https://change.me.example.invalid/updates.json" #optional
# A URL for the "homepage" for this mod, displayed in the mod UI
#displayURL="https://change.me.to.your.mods.homepage.example.invalid/" #optional
# A file name (in the root of the mod JAR) containing a logo for display
#logoFile="examplemod.png" #optional
# A text field displayed in the mod UI
credits="Thanks for this example mod goes to Java" #optional
# A text field displayed in the mod UI
authors="]==] .. (vim.env.USER or "Your Name") .. [==[" #optional
# The description text for the mod (multi line!) (#mandatory)
description='''A short description of the mod'''
# A dependency - use the . to indicate dependency for a specific modid. Dependencies are optional.
[[dependencies.]==] .. string.lower(project_name):gsub(" ", "_") .. [==[]

modId="forge"
mandatory=true
versionRange="[47,)"
ordering="NONE"
side="BOTH"

[[dependencies.]==] .. string.lower(project_name):gsub(" ", "_") .. [==[]

modId="minecraft"
mandatory=true
versionRange="[1.20.1,1.21)"
ordering="NONE"
side="BOTH"
]==]
    write_file(project_path .. "/src/main/resources/META-INF/mods.toml", mods_toml)

    -- Create build.gradle for Forge
    local forge_build_gradle = [[plugins {
	id 'eclipse'
	id 'idea'
	id 'maven-publish'
	id 'net.minecraftforge.gradle' version '[6.0,6.2)'
}

version = '1.0.0'
group = 'com.yourname.' .. project_name:gsub(" ", "_"):lower()

java {
	withSourcesJar()
}

minecraft {
	mappings channel: 'official', version: '1.20.1'

	copyIdeResources = true

	runs {
		client {
			workingDirectory project.file('run')

			property 'forge.logging.markers', 'REGISTRIES'

			property 'forge.logging.console.level', 'debug'

			mods {
				examplemod {
					source sourceSets.main
				}
			}
		}

		server {
			workingDirectory project.file('run')

			property 'forge.logging.markers', 'REGISTRIES'

			property 'forge.logging.console.level', 'debug'

			mods {
				examplemod {
					source sourceSets.main
				}
			}
		}

		data {
			workingDirectory project.file('run')

			property 'forge.logging.markers', 'REGISTRIES'

			property 'forge.logging.console.level', 'debug'

			args '--mod', 'examplemod', '--all', '--output', file('src/generated/resources/'), '--existing', file('src/main/resources/')

			mods {
				examplemod {
					source sourceSets.main
				}
			}
		}
	}
}

sourceSets.main.resources { srcDir 'src/generated/resources' }

repositories {

}

dependencies {
	minecraft 'net.minecraftforge:forge:1.20.1-47.2.0'
}

jar {
	manifest {
		attributes([
				"Specification-Title"     : "]] .. project_name .. [[",
				"Specification-Vendor"    : "]] .. vim.env.USER or "Your Name" .. [[",
				"Specification-Version"   : "1",
				"Implementation-Title"    : project.name,
				"Implementation-Version"  : project.jar.version,
				"Implementation-Vendor"   : "]] .. vim.env.USER or "Your Name" .. [[",
				"Implementation-Timestamp": new Date().format("yyyy-MM-dd'T'HH:mm:ssZ")
		])
	}
}

jar.finalizedBy('reobfJar')

publishing {
	publications {
		mavenJava(MavenPublication) {
			artifact jar
		}
	}
	tasks.publish.dependsOn 'build'
}
]]
    write_file(project_path .. "/build.gradle", forge_build_gradle)

    -- Create main Java class for Forge
    local main_class_name = string.gsub(project_name, "%s+", ""):lower()
    local forge_main_java = [[package ]]
        .. main_class_name
        .. [[;

import net.minecraftforge.fml.common.Mod;

@Mod("]]
        .. string.lower(project_name):gsub(" ", "_")
        .. [[")
public class Main {

    public Main() {
    }
}
]]
    create_dir(project_path .. "/src/main/java/" .. main_class_name:gsub("%.", "/"))
    write_file(project_path .. "/src/main/java/" .. main_class_name .. "/Main.java", forge_main_java)
end

-- Function to create Quilt mod structure
function M.create_quilt_mod(project_path, project_name, version)
    -- Create quilt.mod.json
    local quilt_json = [[{
  "schema_version": 1,
  "quilt_loader": {
    "group": "com.yourname",
    "id": "]] .. string.lower(project_name):gsub(" ", "_") .. [[",
    "version": "${version}",
    "metadata": {
      "name": "]] .. project_name .. [[",
      "description": "A Quilt mod",
      "contributors": {
        "Your Name": "Owner"
      },
      "contact": {
        "homepage": "https://quiltmc.org",
        "issues": "https://github.com/YOUR_USERNAME/YOUR_REPOSITORY/issues",
        "sources": "https://github.com/YOUR_USERNAME/YOUR_REPOSITORY"
      },
      "license": "CC0-1.0"
    },
    "intermediate_mappings_target": "net.fabricmc:yarn:${project.yarn_mappings}:v2",
    "depends": [
      {
        "id": "quilt_loader",
        "version": "*"
      },
      {
        "id": "minecraft",
        "version": "]] .. version .. [["
      }
    ]
  },
  "minecraft": {
    "environment": "*"
  }
}]]

    write_file(project_path .. "/src/main/resources/quilt.mod.json", quilt_json)

    -- Create build.gradle for Quilt
    local quilt_build_gradle = [[plugins {
	id 'org.quiltmc.loom' version '1.3.5'
	id 'java'
}

version = project.mod_version
group = project.maven_group

repositories {
	maven {
		name = 'Quilt'
		url = 'https://maven.quiltmc.org/repository/release'
	}
	// Add repositories to retrieve artifacts from in here.
	// You should only use this when depending on other mods because
	// Loom adds the essential maven repositories to resolve dependencies.
}

dependencies {
	// To change the versions see the gradle.properties file
	minecraft "com.mojang:minecraft:${project.minecraft_version}"
	mappings "org.quiltmc:quilt-mappings:${project.yarn_mappings}:v2"
	modImplementation "org.quiltmc:quilt-loader:${project.loader_version}"
}

processResources {
	inputs.property "version", project.version

	filesMatching("quilt.mod.json") {
		expand "version": project.version
	}
}

tasks.withType(JavaCompile).configureEach {
	it.options.release = 17
}

java {
	// Loom will automatically attach sourcesJar to a RemapSourcesJar task and to the "build" task
	// if it is present.
	// If you remove this line, sources will not be generated.
	withSourcesJar()

	sourceCompatibility = JavaVersion.VERSION_17
	targetCompatibility = JavaVersion.VERSION_17
}

jar {
	from("LICENSE") {
		rename { "${it}_${project.base.archivesName.get()}"}
	}
}
]]
    write_file(project_path .. "/build.gradle", quilt_build_gradle)

    -- Create gradle.properties for Quilt
    local quilt_gradle_properties = [[# Done to increase the memory available to gradle.
org.gradle.jvmargs=-Xmx1G
org.gradle.parallel=true

# Quilt Properties
# check these on https://lambdaurora.dev/tools/import_quilt.html
minecraft_version=]] .. version .. [[
yarn_mappings=1.20.1+build.10
loader_version=0.18.1-beta.3

# Mod Properties
mod_version = 1.0.0
maven_group = com.yourname
archives_base_name = ]] .. project_name:gsub(" ", "_"):lower() .. [[
]]
    write_file(project_path .. "/gradle.properties", quilt_gradle_properties)

    -- Create settings.gradle for Quilt
    local quilt_settings_gradle = [[pluginManagement {
	repositories {
		maven {
			name = 'Quilt'
			url = 'https://maven.quiltmc.org/repository/release'
		}
		mavenCentral()
		gradlePluginPortal()
	}
}
]]
    write_file(project_path .. "/settings.gradle", quilt_settings_gradle)

    -- Create main Java class for Quilt
    local main_class_name = string.gsub(project_name, "%s+", ""):lower()
    local quilt_main_java = [[package ]]
        .. main_class_name
        .. [[;

import org.quiltmc.loader.api.ModContainer;
import org.quiltmc.qsl.base.api.entrypoint.ModInitializer;

public class Main implements ModInitializer {
	@Override
	public void onInitialize(ModContainer mod) {
		System.out.println("Hello Quilt world!");
	}
}
]]
    create_dir(project_path .. "/src/main/java/" .. main_class_name:gsub("%.", "/"))
    write_file(project_path .. "/src/main/java/" .. main_class_name .. "/Main.java", quilt_main_java)
end

-- Function to create .gitignore
function M.create_gitignore(project_path)
    local gitignore_content = [[# Compiled class file
*.class

# Log file
*.log

# BlueJ files
*.ctxt

# Mobile Tools for Java (J2ME)
.mtj.tmp/
.mwj.tmp/
.mjw.tmp/

# Package Files #
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# virtual machine crash logs, see http://www.java.com/en/download/help/error_hotspot.xml
hs_err_pid*

# Gradle
.gradle/
build/

# Minecraft
.run/
config/
logs/

# IntelliJ IDEA
.idea/
*.iml
*.iws

# Eclipse
.metadata
bin/
tmp/
*.tmp
*.bak
*.swp
*~.nib
local.properties
.settings/
.loadpath
.recommenders

# NetBeans
/nbproject/private/
/nbbuild/
/dist/
/nbdist/
/.nb-gradle/

# VSCode
.vscode/

# Fabric
.local_minecraft/

# Forge
libraries/
out/
]]

    write_file(project_path .. "/.gitignore", gitignore_content)
end

-- Function to create README.md
function M.create_readme(project_path, project_name, mod_type, version)
    local readme_content = "# "
        .. project_name
        .. "\n\n"
        .. "A Minecraft "
        .. mod_type
        .. " mod for version "
        .. version
        .. ".\n\n"
        .. "## Development\n\n"
        .. "To set up the development environment:\n\n"
        .. "1. Install JDK 17 or higher\n"
        .. "2. Run `./gradlew genSources` to generate sources\n"
        .. "3. Import the project into your IDE\n\n"
        .. "For more information about "
        .. mod_type
        .. " modding, visit the official documentation."

    write_file(project_path .. "/README.md", readme_content)
end

return M
