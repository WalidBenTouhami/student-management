import jenkins.model.*
import hudson.tasks.Mailer
import hudson.plugins.emailext.*

def instance = Jenkins.getInstance()

// 1. Configure standard Mailer (often used as fallback)
def mailer = instance.getDescriptorByType(Mailer.DescriptorImpl.class)
mailer.setSmtpHost("smtp.gmail.com")
mailer.setSmtpPort("587")
mailer.setUseSsl(false) // STARTTLS, not implicit SSL
mailer.setSmtpAuth("ds.walid.bentouhami@gmail.com", "izos kdzh irco qlgj")
mailer.setReplyToAddress("walid.bentouhami@esprit.tn")
mailer.setCharset("UTF-8")
mailer.save()

// 2. Configure Extended E-mail Notification (emailext)
def emailExt = instance.getDescriptorByType(ExtendedEmailPublisherDescriptor.class)
emailExt.setSmtpServer("smtp.gmail.com")
emailExt.setSmtpPort("587")
emailExt.setUseSsl(false) // TLS
emailExt.setSmtpAuth("ds.walid.bentouhami@gmail.com", "izos kdzh irco qlgj")
emailExt.setDefaultReplyTo("walid.bentouhami@esprit.tn")
emailExt.setCharset("UTF-8")

// Force STARTTLS for Gmail on port 587
emailExt.getMailAccount().setSmtpHost("smtp.gmail.com")
emailExt.getMailAccount().setSmtpPort("587")
emailExt.getMailAccount().setUseSsl(false)
emailExt.getMailAccount().setAddress("ds.walid.bentouhami@gmail.com")
// emailExt uses advanced properties for STARTTLS in modern Jenkins
emailExt.setAdvProperties("mail.smtp.starttls.enable=true")

// Configuration par défaut
emailExt.setDefaultContentType("text/html")
emailExt.setDefaultSubject("\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS!")
emailExt.setDefaultBody("Check console output at \$BUILD_URL to view the results.")
emailExt.save()

instance.save()
println "Configuration SMTP (Extended E-mail) terminée."
