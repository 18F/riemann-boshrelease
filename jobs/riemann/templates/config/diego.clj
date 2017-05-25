(defn diego-alerts [pd warn-disk crit-disk crit-mem warn-mem crit-containers warn-containers crit-task warn-task]
  (info "Setting up diego alerts")

  (sdo
    (where (service "cf.rep.CapacityRemainingDisk")
      (smap
        (fn [event]
          (assoc event
            :state (cond
              (< (:metric event) crit-disk) "critical"          
              (< (:metric event) warn-disk) "warn"          
              :else "ok"
            )
          )
        )
        #(warn %)
      )
    )

    (where (service "cf.rep.CapacityRemainingMemory")
      (smap
        (fn [event]
          (assoc event
            :state (cond
              (< (:metric event) crit-mem) "critical"          
              (< (:metric event) warn-mem) "warn"          
              :else "ok"
            )
          )
        )
        #(warn %)
      )
    )

    (where (service "cf.rep.CapacityRemainingContainers")
      (smap
        (fn [event]
          (assoc event
            :state (cond
              (< (:metric event) crit-containers) "critical"          
              (< (:metric event) warn-containers) "warn"          
              :else "ok"
            )
          )
        )
        #(warn %)
      )
    )

    (where (service "cf.auctioneer.AuctioneerLRPAuctionsFailed")
      (smap
        (fn [event]
          (assoc event
            :state (cond
              (< (:metric event) crit-lrp) "critical"          
              (< (:metric event) warn-lrp) "warn"          
              :else "ok"
            )
          )
        )
        #(warn %)
      )
    )

    (where (service "cf.auctioneer.AuctioneerTaskAuctionsFailed")
      (smap
        (fn [event]
          (assoc event
            :state (cond
              (< (:metric event) crit-task) "critical"          
              (< (:metric event) warn-task) "warn"          
              :else "ok"
            )
          )
        )
        #(warn %)
      )
    )
  )
)
