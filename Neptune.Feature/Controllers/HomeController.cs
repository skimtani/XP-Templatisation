using Neptune.Feature.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Sitecore.XA.Foundation.Mvc.Controllers;
using Sitecore.Mvc.Controllers;

namespace Neptune.Feature.Controllers
{
    public class HomeController : SitecoreController
    {
        public ActionResult GetTitle()
        {
            var clientname = Sitecore.Configuration.Settings.GetSetting("Client_Name");
            TitleComponentModel model = new TitleComponentModel();
            model.Title = clientname;
            return View("/Views/Home/Title.cshtml",model);
        }


        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }
    }
}