package edu.ucdenver.ccp.PhenoGen.tools.analysis;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import javax.mail.MessagingException;
import javax.mail.SendFailedException;

import javax.servlet.http.HttpSession;

import edu.ucdenver.ccp.util.Debugger;
import edu.ucdenver.ccp.PhenoGen.data.Dataset;
import edu.ucdenver.ccp.PhenoGen.data.Dataset.DatasetVersion;
import edu.ucdenver.ccp.PhenoGen.data.User;
import edu.ucdenver.ccp.PhenoGen.driver.ExecHandler;
import edu.ucdenver.ccp.PhenoGen.web.mail.Email;
import edu.ucdenver.ccp.PhenoGen.driver.RException;
import edu.ucdenver.ccp.PhenoGen.driver.R_session;
import edu.ucdenver.ccp.util.ObjectHandler;
import edu.ucdenver.ccp.util.sql.PropertiesConnection;

/* for handling exceptions in Threads */
import au.com.forward.threads.ThreadReturn;
import au.com.forward.threads.ThreadInterruptedException;
import au.com.forward.threads.ThreadException;
import java.io.*;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.DecimalFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.logging.Level;



/* for logging messages */
import org.apache.log4j.Logger;

public class AsyncGeneDataTools extends Thread {
        private String[] rErrorMsg = null;
        HttpSession session=null;
        private Logger log = null;
        private String userFilesRoot = "";
        private String urlPrefix = "";
        private String ucscDir="";
        private Connection dbConn = null;
        private String dbPropertiesFile=null;
        String outputDir="";
        String chrom="";
        
        int minCoord=0;
        int maxCoord=0;
        int arrayTypeID=0;
        int rnaDatasetID=0;
        int usageID=0;
        boolean done=false;
        String updateSQL="update TRANS_DETAIL_USAGE set TIME_ASYNC_GENE_DATA_TOOLS=? , RESULT=? where TRANS_DETAIL_ID=?";
        
    public AsyncGeneDataTools(HttpSession inSession,String outputDir,String chr,int min,int max,int arrayTypeID,int rnaDS_ID,int usageID) {
                this.session = inSession;
                this.outputDir=outputDir;
                log = Logger.getRootLogger();
                log.debug("in AsynGeneDataTools()");
                this.session = inSession;
                
                this.chrom=chr;
                this.minCoord=min;
                this.maxCoord=max;
                this.arrayTypeID=arrayTypeID;
                this.rnaDatasetID=rnaDS_ID;
                this.usageID=usageID;

                log.debug("start");

                //this.selectedDataset = (Dataset) session.getAttribute("selectedDataset");
                //this.selectedDatasetVersion = (Dataset.DatasetVersion) session.getAttribute("selectedDatasetVersion");
                //this.publicDatasets = (Dataset[]) session.getAttribute("publicDatasets");
                this.dbConn = (Connection) session.getAttribute("dbConn");
                dbPropertiesFile = (String) session.getAttribute("dbPropertiesFile");
                //log.debug("db");
                
                String contextRoot = (String) session.getAttribute("contextRoot");
                //log.debug("context" + contextRoot);
                String appRoot = (String) session.getAttribute("applicationRoot");
                //log.debug("app" + appRoot);
                
                //log.debug("userFilesRoot");
                this.urlPrefix = (String) session.getAttribute("mainURL");
                if (urlPrefix.endsWith(".jsp")) {
                    urlPrefix = urlPrefix.substring(0, urlPrefix.lastIndexOf("/") + 1);
                }
                //log.debug("mainURL");
                
                this.ucscDir = (String) session.getAttribute("ucscDir");
                //log.debug("ucsc");
                
                
    }
    
    

    public void run() throws RuntimeException {
        done=false;
        boolean closeDB=false;
        if(dbPropertiesFile!=null&&!dbPropertiesFile.equals("")){
            Connection oldDB=dbConn;
            try{
                dbConn = new PropertiesConnection().getConnection(dbPropertiesFile);
                if(dbConn==null||dbConn.isClosed()){
                    dbConn=oldDB;
                }else{
                    closeDB=true;
                }
            }catch(Exception e){
                dbConn=oldDB;
            }
        }
        Date start=new Date();
        try{
            callDEHeatMap(outputDir,chrom, minCoord, maxCoord,arrayTypeID,rnaDatasetID);
            callPanelHerit(outputDir,chrom, minCoord, maxCoord,arrayTypeID,rnaDatasetID);
            outputProbesetIDFiles(outputDir,chrom, minCoord, maxCoord,arrayTypeID,rnaDatasetID);
            done=true;
            Date end=new Date();
            try{
                PreparedStatement ps=dbConn.prepareStatement(updateSQL);
                long returnTimeMS=end.getTime()-start.getTime();
                ps.setLong(1, returnTimeMS);
                ps.setString(2, "AsyncGeneDataTools completed successfully");
                ps.setInt(3, usageID);
                int updated=ps.executeUpdate();
                log.debug("AsyncGeneDataTools: updated "+updated +"records");
                ps.close();
            }catch(SQLException e){
                log.error("Error saving AsyncGeneDataTools Timing",e);
            }
            
            log.debug("AsyncGeneDataTools DONE");
        } catch (Exception ex) {
            done=true;
            log.error("Error processing initial files in AsyncGeneDataTools",ex);
            Date end=new Date();
            try{
                PreparedStatement ps=dbConn.prepareStatement(updateSQL);
                long returnTimeMS=end.getTime()-start.getTime();
                ps.setLong(1, returnTimeMS);
                ps.setString(2, "AsyncGeneDataTools had errors:"+ex.getMessage());
                ps.setInt(3, usageID);
                ps.executeUpdate();
                ps.close();
            }catch(SQLException e){
                log.error("Error saving AsyncGeneDataTools Timing",e);
            }
            String fullerrmsg=ex.getMessage();
                    StackTraceElement[] tmpEx=ex.getStackTrace();
                    for(int i=0;i<tmpEx.length;i++){
                        fullerrmsg=fullerrmsg+"\n"+tmpEx[i];
                    }
            Email myAdminEmail = new Email();
            myAdminEmail.setSubject("Exception thrown in AsyncGeneDataTools");
            myAdminEmail.setContent("There was an error while running AsyncGeneDataTools \nStackTrace:\n"+fullerrmsg);
            try {
                myAdminEmail.sendEmailToAdministrator();
            } catch (Exception mailException) {
                log.error("error sending message", mailException);
                throw new RuntimeException();
            }
        }
        if(closeDB){
            try {
                dbConn.close();
            } catch (SQLException ex) {
                log.error("error closing DB", ex);
            }
        }
        done=true;
    }
    
    private void outputProbesetIDFiles(String outputDir,String chr, int min, int max,int arrayTypeID,int rnaDS_ID){
        String probeQuery="select s.Probeset_ID "+
                                "from Chromosomes c, Affy_Exon_ProbeSet s "+
                                "where s.chromosome_id = c.chromosome_id "+
                                "and substr(c.name,1,2) = '"+chr+"' "+
                            "and "+
                            "((s.psstart >= "+min+" and s.psstart <="+max+") OR "+
                            "(s.psstop >= "+min+" and s.psstop <= "+max+")) "+
                            "and s.psannotation <> 'transcript' " +
                            "and s.Array_TYPE_ID = "+arrayTypeID;
        
        String probeTransQuery="select s.Probeset_ID,c.name,s.PSSTART,s.PSSTOP,s.PSLEVEL "+
                                "from Chromosomes c, Affy_Exon_ProbeSet s "+
                                "where s.chromosome_id = c.chromosome_id "+
                                "and substr(c.name,1,2) = '"+chr+"' "+
                            "and "+
                            "((s.psstart >= "+min+" and s.psstart <="+max+") OR "+
                            "(s.psstop >= "+min+" and s.psstop <= "+max+")) "+
                            "and s.psannotation like 'transcript' " +
                            "and s.Array_TYPE_ID = " + arrayTypeID +
                            " and exists(select l.probe_id from location_specific_eqtl l where s.probeset_id = l.probe_id)";
        
        log.debug("PSLEVEL SQL:"+probeQuery);
        log.debug("Transcript Level SQL:"+probeTransQuery);
            String pListFile=outputDir+"tmp_psList.txt";
            try{
                BufferedWriter psout=new BufferedWriter(new FileWriter(new File(pListFile)));
                try{
                    PreparedStatement ps = dbConn.prepareStatement(probeQuery);
                    ResultSet rs = ps.executeQuery();
                    while (rs.next()) {
                        int psid = rs.getInt(1);
                        psout.write(psid + "\n");
                    }
                    ps.close();
                }catch(SQLException ex){
                    log.error("Error getting exon probesets",ex);
                }
                psout.flush();
                psout.close();
            }catch(IOException e){
                log.error("Error writing exon probesets",e);
            }
            done=true;
            String ptransListFiletmp = outputDir + "tmp_psList_transcript.txt";
            String ptransListFile = outputDir + "tmp_psList_transcript.txt";
            File srcFile=new File(ptransListFiletmp);
            File destFile=new File(ptransListFile);
            try{
                BufferedWriter psout = new BufferedWriter(new FileWriter(srcFile));
                try{
                    PreparedStatement ps = dbConn.prepareStatement(probeTransQuery);
                    ResultSet rs = ps.executeQuery();
                    while (rs.next()) {
                        int psid = rs.getInt(1);
                        String ch = rs.getString(2);
                        int start = rs.getInt(3);
                        int stop = rs.getInt(4);
                        String level=rs.getString(5);
                        psout.write(psid + "\t" + ch + "\t" + start + "\t" + stop + "\t" + level + "\n");
                    }
                    ps.close();
                }catch(SQLException ex){
                    log.error("Error getting transcript probesets",ex);
                }
                psout.flush();
                psout.close();
            }catch(IOException e){
                log.error("Error writing transcript probesets",e);
            }
            srcFile.renameTo(destFile);
            
    }
    
    public boolean callDEHeatMap(String outputDir,String chr, int min, int max,int arrayTypeID,int rnaDS_ID){
        boolean error=false;
        //create DE mean heatmap
        String meanQuery="select dem.probeset_id,dem.mean,dad.tissue,des.strain_name from de_means dem, de_arrays_dataset dad,de_strains des "+
                         "where des.diff_exp_id=dad.diff_exp_id "+
                         "and des.de_strain_id = dem.de_strain_id "+
                         "and dad.diff_exp_id=dem.diff_exp_id "+
                         "and dem.diff_exp_id in (select rdd.diff_exp_id from rnadataset_dedataset rdd where rdd.rna_dataset_id = "+rnaDS_ID+") "+
                            "and dem.probeset_id in ("+
                                "select s.Probeset_ID "+
                                "from Chromosomes c, Affy_Exon_ProbeSet s "+
                                "where s.chromosome_id = c.chromosome_id "+
                                "and substr(c.name,1,2) = '"+chr+"' "+
                            "and "+
                            "((s.psstart >= "+min+" and s.psstart <="+max+") OR "+
                            "(s.psstop >= "+min+" and s.psstop <= "+max+")) "+
                            "and s.psannotation <> 'transcript' " +
                            "and s.Array_TYPE_ID = "+arrayTypeID+") "+ 
                            "order by dem.probeset_id,dad.tissue,des.strain_name";
        
        String foldchangeQuery="select def.probeset_id,def.foldchange,def.fdr,def.pvalue,dad.tissue,des1.strain_name as strain1,des2.strain_name as strain2 from de_foldchange def, de_arrays_dataset dad,de_strains des1, de_strains des2 "+
                    "where des1.diff_exp_id=dad.diff_exp_id "+
                    "and des2.diff_exp_id=dad.diff_exp_id "+
                    "and def.strain_id1 = des1.de_strain_id "+
                    "and def.strain_id2 = des2.de_strain_id "+
                    "and dad.diff_exp_id=def.diff_exp_id  "+
                    "and def.diff_exp_id in (select rdd.diff_exp_id from rnadataset_dedataset rdd where rdd.rna_dataset_id = "+rnaDS_ID+") "+
                    "and def.probeset_id in ( "+
                                "select s.Probeset_ID "+
                                "from Chromosomes c, Affy_Exon_ProbeSet s "+
                                "where s.chromosome_id = c.chromosome_id "+
                                "and substr(c.name,1,2) = '"+chr+"' "+
                                "and  "+
                                "((s.psstart >= "+min+" and s.psstart <="+max+") OR "+
                                "(s.psstop >= "+min+" and s.psstop <= "+max+")) "+
                                "and s.psannotation <> 'transcript' "+
                                "and s.Array_TYPE_ID = "+arrayTypeID+")  "+
                    "order by def.probeset_id,dad.tissue,des1.strain_name,des2.strain_name";
        try{
            log.debug("SQL\n"+meanQuery);
            PreparedStatement ps = dbConn.prepareStatement(meanQuery);
            ResultSet rs = ps.executeQuery();
            ArrayList<HashMap> data=new ArrayList<HashMap>();
            ArrayList<String> tissueList=new ArrayList<String>();
            ArrayList<String> strainList=new ArrayList<String>();
            HashMap templine=new HashMap();
            HashMap tissueTH=new HashMap();
            HashMap strainTH=new HashMap();
            String curprobeset="";
            while(rs.next()){
                String probeset=Integer.toString(rs.getInt("PROBESET_ID"));
                double mean=rs.getDouble("MEAN");
                String tissue=rs.getString("TISSUE");
                String strain=rs.getString("STRAIN_NAME");
                if(probeset.equals(curprobeset)){
                    if(templine.containsKey(tissue)){
                        HashMap strainhm=(HashMap)templine.get(tissue);
                        strainhm.put(strain,mean);
                    }else{
                        HashMap strainhm=new HashMap();
                        strainhm.put(strain, mean);
                        templine.put(tissue, strainhm);
                    }
                }else{//newline
                    if(!templine.isEmpty()){
                        data.add(templine);
                    }
                    templine=new HashMap();
                    HashMap strainhm=new HashMap();
                    strainhm.put(strain, mean);
                    templine.put(tissue, strainhm);
                    templine.put("probeset",probeset);
                    curprobeset=probeset;
                }
                if(!tissueTH.containsKey(tissue)){
                    tissueTH.put(tissue, 1);
                    tissueList.add(tissue);
                }
                if(!strainTH.containsKey(strain)){
                    strainTH.put(strain, 1);
                    strainList.add(strain);
                }
            }
            ps.close();
            DecimalFormat df = new DecimalFormat("#############.##");
            try{
            BufferedWriter out=new BufferedWriter(new FileWriter(new File(outputDir+"DE_means.csv")));
            //this.deMeanURL=outputDir+"DE_means.csv";
            out.write("Probeset");
            for(int j=0;j<tissueList.size();j++){
                String tissue=tissueList.get(j);    
                for(int k=0;k<strainList.size();k++){
                        String strain=strainList.get(k);
                        out.write(","+tissue+"."+strain+".Mean");
                }
            }
            out.write("\n");
            for(int i=0;i<data.size();i++){
                HashMap thm=data.get(i);
                String pset=(String)thm.get("probeset");
                out.write(pset);
                for(int j=0;j<tissueList.size();j++){
                    HashMap shm=(HashMap)thm.get(tissueList.get(j));
                    if(shm!=null){
                        for(int k=0;k<strainList.size();k++){
                           Object tmp=shm.get(strainList.get(k));
                           if(tmp!=null){
                               double tmpdbl=Double.parseDouble(tmp.toString());
                               out.write(","+df.format(tmpdbl));
                           }else{
                               out.write(",0");
                           }
                        }
                    }else{
                        for(int k=0;k<strainList.size();k++){
                            out.write(",0");
                        }
                    }
                }
                out.write("\n");
            }
            out.close();
           
            }catch(IOException er){
                error=true;
                log.error("Error outputting means ",er);
            }
        }catch(SQLException e){
            error=true;
            log.error("Error getting dataset id",e);
        }
        //create DE foldchange heatmap
        try{
           log.debug("SQL\n"+foldchangeQuery);
            PreparedStatement ps = dbConn.prepareStatement(foldchangeQuery);
            ResultSet rs = ps.executeQuery();
            ArrayList<HashMap> data=new ArrayList<HashMap>();
            ArrayList<String> tissueList=new ArrayList<String>();
            ArrayList<String> strainList=new ArrayList<String>();
            HashMap templine=new HashMap();
            HashMap tissueTH=new HashMap();
            HashMap strainTH=new HashMap();
            String curprobeset="";
            while(rs.next()){
                String probeset=Integer.toString(rs.getInt("PROBESET_ID"));
                double foldchange=rs.getDouble("foldchange");
                double fdr=rs.getDouble("fdr");
                double pval=rs.getDouble("pvalue");
                String tissue=rs.getString("TISSUE");
                String strain1=rs.getString("strain1");
                String strain2=rs.getString("strain2");
                String strain=strain1+" vs "+strain2;
                if(probeset.equals(curprobeset)){
                    if(templine.containsKey(tissue)){
                        HashMap strainhm=(HashMap)templine.get(tissue);
                        HashMap values=new HashMap();
                        values.put("fdr",fdr);
                        values.put("pvalue",pval);
                        values.put("folddiff",foldchange);
                        strainhm.put(strain, values);
                    }else{
                        HashMap strainhm=new HashMap();
                        HashMap values=new HashMap();
                        values.put("fdr",fdr);
                        values.put("pvalue",pval);
                        values.put("folddiff",foldchange);
                        strainhm.put(strain, values);
                        templine.put(tissue, strainhm);
                    }
                }else{//newline
                    if(!templine.isEmpty()){
                        data.add(templine);
                    }
                    templine = new HashMap();
                    HashMap strainhm=new HashMap();
                    HashMap values=new HashMap();
                    values.put("fdr",fdr);
                    values.put("pvalue",pval);
                    values.put("folddiff",foldchange);
                    strainhm.put(strain, values);
                    templine.put(tissue, strainhm);
                    templine.put("probeset", probeset);
                    curprobeset=probeset;
                }
                if(!tissueTH.containsKey(tissue)){
                    tissueTH.put(tissue, 1);
                    tissueList.add(tissue);
                }
                if(!strainTH.containsKey(strain)){
                    strainTH.put(strain, 1);
                    strainList.add(strain);
                }
            }
            ps.close();
            DecimalFormat df = new DecimalFormat("#############.##");
            try{
            BufferedWriter out=new BufferedWriter(new FileWriter(new File(outputDir+"DE_folddiff.csv")));
            //this.deFoldDiffURL=outputDir+"DE_folddiff.csv";
            out.write("Probeset");
            for(int j=0;j<tissueList.size();j++){
                String tissue=tissueList.get(j);    
                for(int k=0;k<strainList.size();k++){
                        String strain=strainList.get(k);
                        out.write(","+tissue+"."+strain+".FoldDiff"+","+tissue+"."+strain+".Pvalue"+","+tissue+"."+strain+".FDR");
                }
            }
            out.write("\n");
            for(int i=0;i<data.size();i++){
                HashMap thm=data.get(i);
                String pset=(String)thm.get("probeset");
                out.write(pset);
                for(int j=0;j<tissueList.size();j++){
                    HashMap shm=(HashMap)thm.get(tissueList.get(j));
                    if(shm!=null){
                        for(int k=0;k<strainList.size();k++){
                           Object tmp=shm.get(strainList.get(k));
                           if(tmp!=null){
                               HashMap tmphm=(HashMap)tmp;
                               String sfdr=tmphm.get("fdr").toString();
                               String spval=tmphm.get("pvalue").toString();
                               String sfc=tmphm.get("folddiff").toString();
                               double dfdr=Double.parseDouble(sfdr);
                               double dpval=Double.parseDouble(spval);
                               double dfc=Double.parseDouble(sfc);
                               out.write(","+df.format(dfc)+","+df.format(dpval)+","+df.format(dfdr));
                           }else{
                               out.write(",0,0,0");
                           }
                        }
                    }else{
                        for(int k=0;k<strainList.size();k++){
                            out.write(",0,0,0");
                        }
                    }
                }
                out.write("\n");
            }
            out.close();
           
            }catch(IOException er){
                error=true;
                log.error("Error outputting means ",er);
            }
        }catch(SQLException e){
            error=true;
            log.error("Error getting dataset id",e);
        }
        return error;
    }
    
    
    public boolean callPanelHerit(String outputDir,String chr, int min, int max,int arrayTypeID,int rnaDS_ID){
        boolean error=false;
        //create File with Probeset Tissue herit and DABG
        String probeQuery="select phd.probeset_id, rd.tissue, phd.herit,phd.dabg "+
                            "from probeset_herit_dabg phd , rnadataset_dataset rd "+
                            "where rd.rna_dataset_id = "+rnaDS_ID+" "+
                            "and phd.dataset_id=rd.dataset_id "+
                            "and phd.probeset_id in ("+
                                "select s.Probeset_ID "+
                                "from Chromosomes c, Affy_Exon_ProbeSet s "+
                                "where s.chromosome_id = c.chromosome_id "+
                                "and substr(c.name,1,2) = '"+chr+"' "+
                            "and "+
                            "((s.psstart >= "+min+" and s.psstart <="+max+") OR "+
                            "(s.psstop >= "+min+" and s.psstop <= "+max+")) "+
                            "and s.psannotation <> 'transcript' " +
                            "and s.Array_TYPE_ID = "+arrayTypeID+") "+ 
                            "order by phd.probeset_id,rd.tissue";
        
        
        try{
            //log.debug("SQL\n"+meanQuery);
            PreparedStatement ps = dbConn.prepareStatement(probeQuery);
            ResultSet rs = ps.executeQuery();
            ArrayList<HashMap> data=new ArrayList<HashMap>();
            ArrayList<String> tissueList=new ArrayList<String>();
            HashMap templine=new HashMap();
            HashMap tissueTH=new HashMap();
            String curprobeset="";
            while(rs.next()){
                String probeset=Integer.toString(rs.getInt("PROBESET_ID"));
                double herit=rs.getDouble("herit");
                double dabg=rs.getDouble("dabg");
                String tissue=rs.getString("TISSUE");
                if(probeset.equals(curprobeset)){
                        HashMap valueshm=new HashMap();
                        valueshm.put("herit", herit);
                        valueshm.put("dabg",dabg);
                        templine.put(tissue, valueshm);
                
                }else{//newline
                    if(!templine.isEmpty()){
                        data.add(templine);
                    }
                    templine=new HashMap();
                    HashMap valueshm=new HashMap();
                        valueshm.put("herit", herit);
                        valueshm.put("dabg",dabg);
                        templine.put(tissue, valueshm);
                    templine.put("probeset",probeset);
                    curprobeset=probeset;
                }
                if(!tissueTH.containsKey(tissue)){
                    tissueTH.put(tissue, 1);
                    tissueList.add(tissue);
                }
            }
            ps.close();
            DecimalFormat df = new DecimalFormat("#############.###");
            try{
            BufferedWriter out=new BufferedWriter(new FileWriter(new File(outputDir+"Panel_Herit.csv")));
            //this.deMeanURL=outputDir+"DE_means.csv";
            out.write("Probeset");
            for(int j=0;j<tissueList.size();j++){
                String tissue=tissueList.get(j);
                out.write(","+tissue+".Herit,"+tissue+".Dabg");
            }
            out.write("\n");
            for(int i=0;i<data.size();i++){
                HashMap thm=data.get(i);
                String pset=(String)thm.get("probeset");
                out.write(pset);
                for(int j=0;j<tissueList.size();j++){
                    HashMap vhm=(HashMap)thm.get(tissueList.get(j));
                    if(vhm!=null){
                           Object oh=vhm.get("herit");
                           Object od=vhm.get("dabg");
                           if(oh!=null){
                               double tmpdbl=Double.parseDouble(oh.toString());
                               out.write(","+df.format(tmpdbl));
                           }else{
                               out.write(",0");
                           }
                           if(od!=null){
                               double tmpdbl=Double.parseDouble(od.toString());
                               out.write(","+df.format(tmpdbl));
                           }else{
                               out.write(",0");
                           }
                    }else{
                            out.write(",0,0");
                    }
                }
                out.write("\n");
            }
            out.close();
           
            }catch(IOException er){
                error=true;
                log.error("Error outputting means ",er);
            }
        }catch(SQLException e){
            error=true;
            log.error("Error getting dataset id",e);
        }
        return error;
    }
    
    public boolean isDone(){
        return done;
    }
    
}
 
