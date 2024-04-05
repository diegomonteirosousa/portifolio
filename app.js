// Identificar o clique no menu
// Verificar o item que foi clicado e fazer referência com o alvo
// Verificar a distância entre o alvo e o topo
// Animar o scroll até o alvo

const menuItems = document.querySelectorAll('.menu a[href^="#"]');

menuItems.forEach(item => {
  item.addEventListener('click', scrollToIdOnClick);
})

function getScrollTopByHref(element) {
  const id = element.getAttribute('href');
  return document.querySelector(id).offsetTop;
}

function scrollToIdOnClick(event) {
  event.preventDefault();
  const to = getScrollTopByHref(event.target) - 80;
  scrollToPosition(to);
}

function scrollToPosition(to) {
  // window.scroll({
  //   top: to,
  //   behavior: "smooth",
  // });
  smoothScrollTo(0, to);
}

/**
 * Smooth scroll animation
 * @param {int} endX: destination x coordinate
 * @param {int} endY: destination y coordinate
 * @param {int} duration: animation duration in ms
 */
function smoothScrollTo(endX, endY, duration) {
  const startX = window.scrollX || window.pageXOffset;
  const startY = window.scrollY || window.pageYOffset;
  const distanceX = endX - startX;
  const distanceY = endY - startY;
  const startTime = new Date().getTime();

  duration = typeof duration !== 'undefined' ? duration : 400;

  // Easing function
  const easeInOutQuart = (time, from, distance, duration) => {
    if ((time /= duration / 2) < 1) return distance / 2 * time * time * time * time + from;
    return -distance / 2 * ((time -= 2) * time * time * time - 2) + from;
  };

  const timer = setInterval(() => {
    const time = new Date().getTime() - startTime;
    const newX = easeInOutQuart(time, startX, distanceX, duration);
    const newY = easeInOutQuart(time, startY, distanceY, duration);
    if (time >= duration) {
      clearInterval(timer);
    }
    window.scroll(newX, newY);
  }, 1000 / 60); // 60 fps
};



// Função para obter a data atual no formato AAAA-MM-DD
    function getCurrentDate() {
      const now = new Date();
      const year = now.getFullYear();
      let month = now.getMonth() + 1;
      let day = now.getDate();

      // Adiciona zero à frente do mês/dia se forem menores que 10
      month = month < 10 ? '0' + month : month;
      day = day < 10 ? '0' + day : day;

      return year + '-' + month + '-' + day;
    }

    // Função para atualizar o contador de visitas por dia
    function updateVisitCount() {
      const currentDate = getCurrentDate();
      let visitCount = localStorage.getItem(currentDate);

      // Se já houver uma visita registrada para hoje, incrementa o contador
      if (visitCount) {
        visitCount = parseInt(visitCount) + 1;
      } else {
        // Caso contrário, define o contador como 1
        visitCount = 1;
      }

      // Armazena o contador atualizado no armazenamento local
      localStorage.setItem(currentDate, visitCount);

      // Atualiza o texto na página
      document.getElementById('currentDate').textContent = currentDate;
      document.getElementById('visitCount').textContent = "visitante número: " + visitCount;
    }

    // Chama a função para atualizar o contador de visitas ao carregar a página
    updateVisitCount();



VanillaTilt.init(document.querySelector(".teste-img"), {
    max: 25,
    speed: 400
  });
  
  //It also supports NodeList
  VanillaTilt.init(document.querySelectorAll(".teste-img"));
