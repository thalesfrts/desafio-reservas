// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const animatePageEntry = () => {
	const content = document.querySelector("#app-main-content")
	if (!content) return

	content.classList.remove("page-enter")
	requestAnimationFrame(() => {
		content.classList.add("page-enter")
	})
}

document.addEventListener("turbo:before-visit", () => {
	document.body.classList.add("is-navigating")
})

document.addEventListener("turbo:render", () => {
	document.body.classList.remove("is-navigating")
	animatePageEntry()
})

document.addEventListener("turbo:load", () => {
	animatePageEntry()

	const desktopNav = document.querySelector("#desktop-nav")
	const desktopToggle = document.querySelector("[data-desktop-nav-toggle]")

	if (desktopNav && desktopToggle) {
		const collapsedClass = "desktop-nav-collapsed"

		const setDesktopCollapsed = (collapsed) => {
			document.body.classList.toggle(collapsedClass, collapsed)
			desktopToggle.setAttribute("aria-expanded", (!collapsed).toString())
			desktopToggle.setAttribute("aria-label", collapsed ? "Expandir menu lateral" : "Recolher menu lateral")
			desktopToggle.setAttribute("title", collapsed ? "Expandir menu lateral" : "Recolher menu lateral")
			localStorage.setItem("desktopNavCollapsed", collapsed ? "1" : "0")
		}

		const savedCollapsed = localStorage.getItem("desktopNavCollapsed") === "1"
		setDesktopCollapsed(savedCollapsed)

		desktopToggle.onclick = () => {
			setDesktopCollapsed(!document.body.classList.contains(collapsedClass))
		}
	}

	const drawer = document.querySelector("#mobile-nav")
	const overlay = document.querySelector("#mobile-nav-overlay")
	const openButton = document.querySelector("[data-nav-open]")
	const closeButton = document.querySelector("[data-nav-close]")

	if (!drawer || !overlay || !openButton || !closeButton) return

	const setOpen = (isOpen) => {
		if (isOpen) {
			drawer.classList.remove("-translate-x-full")
			overlay.classList.remove("hidden")
			document.body.classList.add("overflow-hidden")
			return
		}

		drawer.classList.add("-translate-x-full")
		overlay.classList.add("hidden")
		document.body.classList.remove("overflow-hidden")
	}

	openButton.onclick = () => setOpen(true)
	closeButton.onclick = () => setOpen(false)
	overlay.onclick = () => setOpen(false)
})
