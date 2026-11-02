package com.ychstudio.jobsys;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;


public class JobBulletin {

    private static final JobBulletin instance = new JobBulletin();
    
    private List<Job> jobList;
    
    private JobBulletin() {
        jobList = new ArrayList<>();
    }
    
    public static JobBulletin getInstance() {
        return instance;
    }
    
    public void addNewJob(Job job) {
        jobList.add(job);
    }
    
    public boolean removeJob(Job job) {
    	return jobList.remove(job);
    }
    
    public Job fetchJob() {
        if (jobList.isEmpty()) {
            return null;
        }
        
        for (Iterator<Job> iterator = jobList.iterator(); iterator.hasNext();) {
            Job job = (Job) iterator.next();
            if (job.taken) {
                if ((System.currentTimeMillis() - job.takenTime) > 10_000) {
                    job.taken = false;
                }
            }
        }
        
        for (Iterator<Job> iterator = jobList.iterator(); iterator.hasNext();) {
            Job job = (Job) iterator.next();
            if (!job.taken) {
                job.taken = true;
                job.takenTime = System.currentTimeMillis();
                return job;
            }
        }
        
        return null;
    }
    
}
