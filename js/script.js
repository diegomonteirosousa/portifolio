

    /* =========================================================
       GSAP
    ========================================================= */

    gsap.registerPlugin(ScrollTrigger);


    /* =========================================================
       CUSTOM CURSOR
    ========================================================= */

    const cursor = document.querySelector(".cursor");
    const cursorRing = document.querySelector(".cursor-ring");

    document.addEventListener("mousemove", e => {

        gsap.to(cursor, {
            x: e.clientX,
            y: e.clientY,
            duration: .1
        });

        gsap.to(cursorRing, {
            x: e.clientX,
            y: e.clientY,
            duration: .3
        });

    });


    /* =========================================================
       NAVBAR
    ========================================================= */

    window.addEventListener("scroll", () => {

        const navbar = document.querySelector(".navbar");

        if(window.scrollY > 80){

            navbar.classList.add("scrolled");

        } else {

            navbar.classList.remove("scrolled");

        }

    });


    /* =========================================================
       HERO
    ========================================================= */

    const heroTimeline = gsap.timeline();

    heroTimeline
        .from(".hero-label", {
            y: 30,
            opacity: 0,
            duration: .8
        })
        .from(".hero-title", {
            y: 70,
            opacity: 0,
            duration: 1,
            ease: "power4.out"
        }, "-=.4")
        .from(".hero-description", {
            y: 30,
            opacity: 0,
            duration: .8
        }, "-=.5")
        .from(".hero-buttons", {
            y: 25,
            opacity: 0,
            duration: .7
        }, "-=.5")
        .from(".hero-circle", {
            scale: .5,
            opacity: 0,
            duration: 1.2,
            ease: "power3.out"
        }, "-=1")
        .from(".hero-photo", {
            y: 80,
            opacity: 0,
            duration: 1.2,
            ease: "power3.out"
        }, "-=.8")
        .from(".hero-number", {
            x: 50,
            opacity: 0,
            duration: .8
        }, "-=.5");


    /* =========================================================
       PARALLAX HERO
    ========================================================= */

    gsap.to(".hero-circle", {

        y: -80,
        rotation: 20,

        scrollTrigger: {
            trigger: ".hero",
            start: "top top",
            end: "bottom top",
            scrub: 1
        }

    });


    gsap.to(".hero-photo", {

        y: 80,

        scrollTrigger: {
            trigger: ".hero",
            start: "top top",
            end: "bottom top",
            scrub: 1
        }

    });


    /* =========================================================
       REVEALS
    ========================================================= */

    gsap.utils.toArray(".reveal-left").forEach(element => {

        gsap.from(element, {

            x: -100,
            opacity: 0,
            duration: 1.2,
            ease: "power3.out",

            scrollTrigger: {
                trigger: element,
                start: "top 80%",
                toggleActions: "play none none reverse"
            }

        });

    });


    gsap.utils.toArray(".reveal-right").forEach(element => {

        gsap.from(element, {

            x: 100,
            opacity: 0,
            duration: 1.2,
            ease: "power3.out",

            scrollTrigger: {
                trigger: element,
                start: "top 80%",
                toggleActions: "play none none reverse"
            }

        });

    });


    /* =========================================================
       SERVICES
    ========================================================= */

   


    /* =========================================================
       PORTFOLIO
    ========================================================= */

    gsap.from(".portfolio-item", {

        y: 100,
        opacity: 0,
        duration: 1,
        stagger: .15,

        scrollTrigger: {
            trigger: "#portfolio",
            start: "top 75%"
        }

    });


    /* =========================================================
       NUMBERS
    ========================================================= */

    document.querySelectorAll(".counter").forEach(counter => {

        const target = Number(counter.dataset.value);

        gsap.to(counter, {

            innerText: target,

            duration: 2,

            snap: {
                innerText: 1
            },

            scrollTrigger: {
                trigger: ".numbers",
                start: "top 80%",
                once: true
            }

        });

    });


    /* =========================================================
       TESTIMONIALS
    ========================================================= */

    gsap.from(".testimonial", {

        y: 70,
        opacity: 0,
        duration: .8,
        stagger: .2,

        scrollTrigger: {
            trigger: "#depoimentos",
            start: "top 75%"
        }

    });


    /* =========================================================
       CTA
    ========================================================= */

    gsap.from(".cta h2", {

        y: 100,
        opacity: 0,
        duration: 1.2,
        ease: "power4.out",

        scrollTrigger: {
            trigger: ".cta",
            start: "top 75%"
        }

    });


    /* =========================================================
       HOVER PROJECTS
    ========================================================= */

    document.querySelectorAll(".project").forEach(project => {

        project.addEventListener("mouseenter", () => {

            gsap.to(project.querySelector(".project-info"), {
                y: -10,
                duration: .4
            });

        });

        project.addEventListener("mouseleave", () => {

            gsap.to(project.querySelector(".project-info"), {
                y: 0,
                duration: .4
            });

        });

    });


    /* =========================================================
       MOBILE MENU CLOSE
    ========================================================= */

    document.querySelectorAll(".nav-link").forEach(link => {

        link.addEventListener("click", () => {

            const menu = document.querySelector("#menu");

            if(menu.classList.contains("show")){

                bootstrap.Collapse
                    .getOrCreateInstance(menu)
                    .hide();

            }

        });

    });



    /* =========================================================
       FOTO DE PERFIL - EFEITO FUTURÍSTICO (SCAN REVEAL)
       Acompanha o mouse e revela foto-perfil-normal.png
       através de uma janela circular sobre a foto-perfil.png
    ========================================================= */

    const photoWrap = document.querySelector(".hero-photo-wrap");

    if (photoWrap) {

        photoWrap.addEventListener("mousemove", e => {

            const rect = photoWrap.getBoundingClientRect();
            const x = ((e.clientX - rect.left) / rect.width) * 100;
            const y = ((e.clientY - rect.top) / rect.height) * 100;

            photoWrap.style.setProperty("--mx", `${x}%`);
            photoWrap.style.setProperty("--my", `${y}%`);

        });

        // suporte a toque (mobile) - efeito segue o dedo
        photoWrap.addEventListener("touchmove", e => {

            const touch = e.touches[0];

            if (!touch) return;

            const rect = photoWrap.getBoundingClientRect();
            const x = ((touch.clientX - rect.left) / rect.width) * 100;
            const y = ((touch.clientY - rect.top) / rect.height) * 100;

            photoWrap.style.setProperty("--mx", `${x}%`);
            photoWrap.style.setProperty("--my", `${y}%`);

        }, { passive: true });

    }


    /* =========================================================
       LOGOS - LOOP INFINITO SEM "PULO"
       Duplica os itens dinamicamente para o translateX(-50%)
       fechar perfeitamente, eliminando o bug visual no loop.
    ========================================================= */

    const logoTrack = document.querySelector(".logo-track");

    if (logoTrack && !logoTrack.dataset.cloned) {

        const originalItems = Array.from(logoTrack.children);

        originalItems.forEach(item => {

            const clone = item.cloneNode(true);
            clone.setAttribute("aria-hidden", "true");
            logoTrack.appendChild(clone);

        });

        logoTrack.dataset.cloned = "true";

    }


    /* =========================================================
       PORTFÓLIO - FILTRO FUNCIONAL
    ========================================================= */

    const filterButtons = document.querySelectorAll(".filter-btn");
    const portfolioItems = document.querySelectorAll(".project");

    filterButtons.forEach(button => {

        button.addEventListener("click", () => {

            filterButtons.forEach(btn => btn.classList.remove("active"));
            button.classList.add("active");

            const filter = button.dataset.filter || "all";

            portfolioItems.forEach(project => {

                const column = project.parentElement;
                const category = project.dataset.category;
                const matches = filter === "all" || category === filter;

                if (matches) {

                    column.classList.remove("is-hidden");
                    project.classList.remove("is-filtering");

                    // força reflow para reiniciar a animação
                    void project.offsetWidth;

                    project.classList.add("is-filtering");

                } else {

                    column.classList.add("is-hidden");

                }

            });

        });

    });

