// Shorthand for $( document ).ready()
$(function() {
    // console.log( "ready!" );
    $(document).swipe( {
        //Generic swipe handler for all directions
        swipe: function(event, direction, distance, duration, fingerCount, fingerData) {
          //change value.
          var el =  $(".swiper");
          el.text("You swiped " + direction );

              // Raise an event to signal that the value changed
              el.trigger("change");
          alert("You swiped " + direction );
          // Raise an event to signal that the value changed
        //   $(this).trigger("change");
        }
      });

    //   $(".swiper").on("click", function(evt) {
    //      alert("you clicked me!")
    //     // evt.target is the button that was clicked
    //     var el = $(evt.target);
      //
    //     // Set the button's text to its current value plus 1
    //     el.text("hi");
      //
    //     // Raise an event to signal that the value changed
    //     el.trigger("change");
    //   });


    var swiperBinding = new Shiny.InputBinding();

    $.extend(swiperBinding, {
      find: function(scope) {
        return $(scope).find(".swiper");
      },
      getValue: function(el) {
        return $(el).text();
      },
      setValue: function(el, value) {
        $(el).text(value);
      },
      subscribe: function(el, callback) {
        $(el).on("change.swiperBinding", function(e) {
          callback();
        });
      },
      unsubscribe: function(el) {
        $(el).off(".swiperBinding");
      }
    });

    Shiny.inputBindings.register(swiperBinding);

});
