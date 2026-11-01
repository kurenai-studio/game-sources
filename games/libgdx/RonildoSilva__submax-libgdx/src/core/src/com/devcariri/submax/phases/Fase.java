package com.devcariri.submax.phases;

import java.util.List;

public class Fase {
	
	private String name;
	private List<Slot> slotlist;

	public Fase(){

	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	
	public List<Slot> getSlots() {
		return slotlist;
	}
	public void setSlots(List<Slot> slotlist) {
		this.slotlist = slotlist;
	}
	
	
}
