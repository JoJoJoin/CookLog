allprojects {
    repositories {
        // 本地在 local.properties 设 cn.mirror=true 可启用国内镜像加速；CI 默认走官方源。
        val useCnMirror =
            run {
                val props = java.util.Properties()
                val f = rootProject.file("local.properties")
                if (f.exists()) f.inputStream().use { props.load(it) }
                props.getProperty("cn.mirror") == "true"
            }
        if (useCnMirror) {
            maven(url = "https://maven.aliyun.com/repository/google")
            maven(url = "https://maven.aliyun.com/repository/public")
        }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
