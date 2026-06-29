import jenkins.model.*
import hudson.tasks.Mailer
import hudson.plugins.emailext.*

def instance = Jenkins.getInstance()

// 1. Configure standard Mailer (often used as fallback)
def mailer = instance.getDescriptorByType(Mailer.DescriptorImpl.class)
mailer.setSmtpHost("smtp.office365.com")
mailer.setSmtpPort("587")
mailer.setUseSsl(false) // Outlook utilise TLS sur le port 587, pas SSL direct
mailer.setSmtpAuth("walid.bentouhami@esprit.tn", "VOTRE_MOT_DE_PASSE")
mailer.setReplyToAddress("walid.bentouhami@esprit.tn")
mailer.setCharset("UTF-8")
mailer.save()

// 2. Configure Extended E-mail Notification (emailext)
def emailExt = instance.getDescriptorByType(ExtendedEmailPublisherDescriptor.class)
emailExt.setSmtpServer("smtp.office365.com")
emailExt.setSmtpPort("587")
emailExt.setUseSsl(false) // TLS
emailExt.setSmtpAuth("walid.bentouhami@esprit.tn", "VOTRE_MOT_DE_PASSE")
emailExt.setReplyToAddress("walid.bentouhami@esprit.tn")
emailExt.setCharset("UTF-8")

// Configuration par défaut
emailExt.setDefaultContentType("text/html")
emailExt.setDefaultSubject("\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS!")
emailExt.setDefaultBody("Check console output at \$BUILD_URL to view the results.")
emailExt.save()

instance.save()
println "Configuration SMTP (Extended E-mail) terminée."
