// Panel de administración de toma6
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import { installConfirm } from "lib/confirm"
import { installMediaState } from "lib/media_state"
import { installAdminForms } from "lib/admin_forms"

const application = Application.start()
eagerLoadControllersFrom("controllers/admin", application)
window.Stimulus = application

installConfirm()
installMediaState()
installAdminForms()
