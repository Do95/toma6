// Sitio público de toma6
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import { installConfirm } from "lib/confirm"
import { installMediaState } from "lib/media_state"

const application = Application.start()
eagerLoadControllersFrom("controllers/site", application)
window.Stimulus = application

installConfirm()
installMediaState()
