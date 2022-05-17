provider "azurerm" {
  features {}
  skip_provider_registration = true
}

variable storageAccountName {}
variable region1 {}
variable region2 {}
variable ExternalIP {}
variable RG {
    description = "Insert the Resource Group Name"
}

##############Storage Account################
resource "azurerm_storage_account" "STA" {
  name                     = var.storageAccountName
  resource_group_name      = var.RG
  location                 = var.region1
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
}
resource "azurerm_storage_share" "fileshare" {
  name                 = "ghost-fileshare"
  access_tier          = "TransactionOptimized"
  storage_account_name = azurerm_storage_account.STA.name
  quota                = 50
}

############## App Service Plan ######################
resource "azurerm_service_plan" "AppServicePlan1" {
  name                = "AppServicePlan-${var.region1}"
  location            = var.region1
  resource_group_name = var.RG
  os_type                = "Linux"
  sku_name = "S1"
}

resource "azurerm_service_plan" "AppServicePlan2" {
  name                = "AppServicePlan-${var.region2}"
  location            = var.region2
  resource_group_name = var.RG
  os_type                = "Linux"
  sku_name = "S1"

}

############## Get the ACR credentials ######################

data "azurerm_container_registry" "ACRcred" {
  name                = "acrbuildcontainer11"
  resource_group_name = var.RG
}

############## Web App ######################
resource "azurerm_linux_web_app" "App1" {
  name                = "appghostblog-${var.region1}"
  location            = var.region1
  resource_group_name = var.RG
  service_plan_id = azurerm_service_plan.AppServicePlan1.id
  https_only = "true"
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.AppInsight.instrumentation_key
    "DOCKER_REGISTRY_SERVER_URL" = "https://${data.azurerm_container_registry.ACRcred.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = data.azurerm_container_registry.ACRcred.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = data.azurerm_container_registry.ACRcred.admin_password
  }
  site_config {
      always_on = "true"
      ftps_state = "FtpsOnly"
      health_check_path = "/"
      health_check_eviction_time_in_min = 2
      application_stack {
    	  docker_image = "acrbuildcontainer11.azurecr.io/ghost/ghost-alpine"
    	  docker_image_tag = "v1"
      }
      scm_ip_restriction  {
        name = "allow-ExternalIP"
        priority ="10"
        action = "Allow"
        ip_address = var.ExternalIP
      }
      ip_restriction  {
        name = "allow-FrontdoorOnly"
        priority ="10"
        action = "Allow"
        service_tag = "AzureFrontDoor.Backend"
      }
      } 
  logs  {
      application_logs {
      	file_system_level = "Error"
        }
      http_logs {
      	file_system {
    	    retention_in_days = "30"
    	    retention_in_mb = "100"
          }
        }
      }
}

resource "azurerm_linux_web_app" "App2" {
  name                = "appghostblog-${var.region2}"
  location            = var.region2
  resource_group_name = var.RG
  service_plan_id = azurerm_service_plan.AppServicePlan2.id
  https_only = "true"
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.AppInsight.instrumentation_key
    "DOCKER_REGISTRY_SERVER_URL" = "https://${data.azurerm_container_registry.ACRcred.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = data.azurerm_container_registry.ACRcred.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = data.azurerm_container_registry.ACRcred.admin_password
  }
  site_config {
      always_on = "true"
      ftps_state = "FtpsOnly"
      health_check_path = "/"
      health_check_eviction_time_in_min = 2
      application_stack {
    	  docker_image = "acrbuildcontainer11.azurecr.io/ghost/ghost-alpine"
    	  docker_image_tag = "v1"
      }
      scm_ip_restriction  {
        name = "allow-ExternalIP"
        priority ="10"
        action = "Allow"
        ip_address = var.ExternalIP
      }
      ip_restriction  {
        name = "allow-FrontdoorOnly"
        priority ="10"
        action = "Allow"
        service_tag = "AzureFrontDoor.Backend"
      }
      } 
  logs  {
      application_logs {
      	file_system_level = "Error"
        }
      http_logs {
      	file_system {
    	    retention_in_days = "30"
    	    retention_in_mb = "100"
          }
        }
      }
}
resource "azurerm_linux_web_app_slot" "App1StagingSlot" {
  name           = "appghostblog-${var.region1}-testing"
  app_service_id = azurerm_linux_web_app.App1.id
  https_only = "true"
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.AppInsight.instrumentation_key
    "DOCKER_REGISTRY_SERVER_URL" = "https://${data.azurerm_container_registry.ACRcred.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = data.azurerm_container_registry.ACRcred.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = data.azurerm_container_registry.ACRcred.admin_password
  }  
  site_config {
      always_on = "true"
      ftps_state = "FtpsOnly"
      health_check_path = "/"
      health_check_eviction_time_in_min = 2
      application_stack {
    	  docker_image = "acrbuildcontainer11.azurecr.io/ghost/ghost-alpine"
    	  docker_image_tag = "v1"
      }
      scm_ip_restriction  {
        name = "allow-ExternalIP"
        priority ="10"
        action = "Allow"
        ip_address = var.ExternalIP
      }
      ip_restriction  {
        name = "allow-FrontdoorOnly"
        priority ="10"
        action = "Allow"
        service_tag = "AzureFrontDoor.Backend"
      }
    } 
  logs  {
      application_logs {
      	file_system_level = "Error"
        }
      http_logs {
      	file_system {
    	    retention_in_days = "30"
    	    retention_in_mb = "100"
          }
        }
      }
}

resource "azurerm_linux_web_app_slot" "App2StagingSlot" {
  name           = "appghostblog-${var.region2}-testing"
  app_service_id = azurerm_linux_web_app.App2.id
  https_only = "true"
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.AppInsight.instrumentation_key
    "DOCKER_REGISTRY_SERVER_URL" = "https://${data.azurerm_container_registry.ACRcred.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = data.azurerm_container_registry.ACRcred.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = data.azurerm_container_registry.ACRcred.admin_password
  }  
  site_config {
      always_on = "true"
      ftps_state = "FtpsOnly"
      health_check_path = "/"
      health_check_eviction_time_in_min = 2
      application_stack {
    	  docker_image = "acrbuildcontainer11.azurecr.io/ghost/ghost-alpine"
    	  docker_image_tag = "v1"
      }
      scm_ip_restriction  {
        name = "allow-ExternalIP"
        priority ="10"
        action = "Allow"
        ip_address = var.ExternalIP
      }
      ip_restriction  {
        name = "allow-FrontdoorOnly"
        priority ="10"
        action = "Allow"
        service_tag = "AzureFrontDoor.Backend"
      }
    } 
  logs  {
      application_logs {
      	file_system_level = "Error"
        }
      http_logs {
      	file_system {
    	    retention_in_days = "30"
    	    retention_in_mb = "100"
          }
        }
      }
}
###########################Autoscaling Rule#################################
resource "azurerm_monitor_autoscale_setting" "AutoscaleRuleApp1" {
  name                = "myAutoscaleSetting"
  resource_group_name = var.RG
  location            = var.region1
  target_resource_id  =azurerm_service_plan.AppServicePlan1.id

  profile {
    name = "Autoscalerule"

    capacity {
      default = 2
      minimum = 2
      maximum = 8
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id =azurerm_service_plan.AppServicePlan1.id #azurerm_linux_web_app.App1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        #metric_namespace   = "microsoft.web/serverfarms"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "6"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "SocketInboundAll"
        metric_resource_id =azurerm_service_plan.AppServicePlan1.id #azurerm_linux_web_app.App1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 200
        #metric_namespace   = "microsoft.web/serverfarms"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "6"
        cooldown  = "PT1M"
      }
    }    

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id =azurerm_service_plan.AppServicePlan1.id #azurerm_linux_web_app.App1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "6"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "SocketInboundAll"
        metric_resource_id =azurerm_service_plan.AppServicePlan1.id #azurerm_linux_web_app.App1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 200
        #metric_namespace   = "microsoft.web/serverfarms"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "6"
        cooldown  = "PT1M"
      }
    }     
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      #custom_emails                         = ["admin@gmail.com"]
    }
  }
}

############# FrontDoor ##############
resource "azurerm_frontdoor" "afd" {
  name                = "ghostblogafd"
  resource_group_name = var.RG

  routing_rule {
    name               = "ForwardingRule"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["ghostapp-frontend"]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "ghostapp-backend"
    }
  }
    routing_rule {
    name               = "http-to-https"
    accepted_protocols = ["Http"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["ghostapp-frontend"]
    redirect_configuration {
      redirect_protocol  = "HttpsOnly"
      redirect_type = "Found"
    }
  }

  backend_pool_settings {
    backend_pools_send_receive_timeout_seconds   = 0
    enforce_backend_pools_certificate_name_check = false 
  }
  backend_pool_load_balancing {
    name = "ghostapp-LoadBalancingSettings"
    additional_latency_milliseconds = 100
  }

  backend_pool_health_probe {
    name = "ghostapp-healthprobe"
    path = "/"
    protocol = "Https"
  }

  backend_pool {
    name = "ghostapp-backend"
    backend {
      host_header = "appghostblog-${var.region1}.azurewebsites.net"
      address     = "appghostblog-${var.region1}.azurewebsites.net"
      http_port   = 80
      https_port  = 443
      priority = "1"
    }
   backend {
     host_header = "appghostblog-${var.region2}.azurewebsites.net"
     address     = "appghostblog-${var.region2}.azurewebsites.net"
     http_port   = 80
     https_port  = 443
     priority = "2"
   }    

    load_balancing_name = "ghostapp-LoadBalancingSettings"
    health_probe_name   = "ghostapp-healthprobe"
  }

  frontend_endpoint {
    name      = "ghostapp-frontend"
    host_name = "ghostblogafd.azurefd.net"
    session_affinity_enabled = "true"
    web_application_firewall_policy_link_id = azurerm_frontdoor_firewall_policy.wafpolicy.id
  }
}

############# WAF Policy ###############
resource "azurerm_frontdoor_firewall_policy" "wafpolicy" {
  name                              = "WAFpolicy"
  resource_group_name               = var.RG
  enabled                           = true
  mode                              = "Prevention"

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "1.1"
  }
}

############# Log Analytics #############
resource "azurerm_log_analytics_workspace" "LogAnalytics" {
  name                = "ghostblog-LogWorkspace"
  location            = var.region1
  resource_group_name = var.RG
  retention_in_days   = 30
}

############## Application Insights ################
resource "azurerm_application_insights" "AppInsight" {
  name                = "ghostblog-AppInsight"
  location            = var.region1
  resource_group_name = var.RG
  application_type    = "web"
}

########## Diagnostic Settings #################
resource "azurerm_monitor_diagnostic_setting" "Webapp1Diagnostic" {
  name               = "diag-ghostapp-${var.region1}"
  target_resource_id = azurerm_linux_web_app.App1.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.LogAnalytics.id

  log {
    category = "AppServiceAppLogs"
    retention_policy {
      enabled = false
    }   
  }
  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "Webapp2Diagnostic" {
  name               = "diag-ghostapp-${var.region2}"
  target_resource_id = azurerm_linux_web_app.App2.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.LogAnalytics.id

  log {
    category = "AppServiceAppLogs"
    retention_policy {
      enabled = false
    }
  }
  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}
output "BlogURL" {
  value = azurerm_frontdoor.afd.cname
}
