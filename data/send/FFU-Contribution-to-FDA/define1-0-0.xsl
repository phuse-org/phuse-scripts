<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
  xsi:schemaLocation="http://www.cdisc.org/ns/odm/v1.2 ODM1-2-1.xsd
   http://www.cdisc.org/ns/def/v1.0 http://www.cdisc.org/schema/def/v1.0/define-extension.xsd"
  xmlns:odm="http://www.cdisc.org/ns/odm/v1.2"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:def="http://www.cdisc.org/ns/def/v1.0"
  xmlns:xlink="http://www.w3.org/1999/xlink">

    <xsl:output method="html" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
  doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" indent="yes"/>

<!-- ****************************************************************************************************** -->
<!-- File: define1-0-0.xsl                                                                                  -->
<!-- Lat modification Date: 25th-Aug-2013                                                                                             -->
<!-- Version: 1.0.4                                                                                         -->
<!-- Author: Percept Pharma Services                                                                                                -->
<!-- ****************************************************************************************************** -->

    <xsl:template match="/">
        <!-- **************************************************** -->
        <!-- Create the HTML Header                               -->
        <!-- **************************************************** -->
        <html>
            <head>
                <link rel="stylesheet" type="text/css" href="define.css"></link>
                <title>
                    <xsl:value-of select="concat('Study ',/odm:ODM/odm:Study/odm:GlobalVariables/odm:StudyName,', Data Definitions')"/>
                </title>
                <script language="javascript">
			<![CDATA[
                            function updateResize(){
					collapse("toc1");
					collapse("toc2");
					collapse("tocb2.1");
					content.style.width = Math.max(document.body.clientWidth - 220, 0);
	                    }

                           function parentClick(idname){
					var Source, Target;
					Source = window.event.srcElement;
                                       if( Source.className.indexOf("tocParent") == 0 ){
						i=1;
						Target = document.getElementById(idname + "." + i.toString());
                                               if (Target != null && Target.style.display == "none"){
							Source.style.listStyleImage = "url(icon3.gif)";
							expand(idname);
						}else{
							Source.style.listStyleImage = "url(icon1.gif)";
							collapse(idname);
						}
					}
					window.event.cancelBubble = true;
				}

                         function expand(idname){
					var i, Target;
					i=1;
					Target = document.getElementById(idname + "." + i.toString());
                                        while( Target != null ){
						Target.style.display = "block";
						expand(idname + "." + i.toString());
						i++;
						Target = document.getElementById(idname + "." + i.toString());
					}
				}

			  function collapse(idname){
				var i, Target;
				i=1;
				Target = document.getElementById(idname + "." + i.toString());
				while( Target != null ){
					  Target.style.display = "none";
					  collapse(idname + "." + i.toString());
					  i++;
					  Target = document.getElementById(idname + "." + i.toString());
				}
			  }
			]]>
                </script>
            </head>
            <body  onload="updateResize();" onresize="updateResize();">
                <div id="menu">
                    <ul>
                        <!-- **************************************************** -->
                        <!-- **************** Annotated CRF ********************* -->
                        <!-- **************************************************** -->
                        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:AnnotatedCRF">
                            <li class="toc">
                                <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:AnnotatedCRF/def:DocumentRef">
                                    <xsl:variable name="leafIDs" select="@leafID"/>
                                    <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafIDs]"/>
                                    <a class="tocItem" target="_blank">
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="$leaf/@xlink:href"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="$leaf/def:title"/>
                                    </a>
                                </xsl:for-each>
                            </li>
                        </xsl:if>

                        <!-- **************************************************** -->
                        <!-- ************** Supplemental Doc ******************* -->
                        <!-- *************************************************** -->
                        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:SupplementalDoc">
                            <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:SupplementalDoc/def:DocumentRef">
                                <xsl:variable name="leafIDs" select="@leafID"/>
                                <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafIDs]"/>
                                <li class="toc" target="_blank">
                                    <a class="tocItem" target="_blank">
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="$leaf/@xlink:href"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="$leaf/def:title"/>
                                    </a>
                                </li>
                            </xsl:for-each>
                        </xsl:if>

                        <!-- **************************************************** -->
                        <!-- ******************  Datasets *********************** -->
                        <!-- **************************************************** -->
                        <xsl:variable name="datasetcount" select="count(/odm:ODM/odm:Study/odm:MetaDataVersion/odm:ItemGroupDef)" />
                        <li id="toc1" class="tocParent" onClick="parentClick('toc1');">
                            <a class="tocItem"  href="#TOP">SEND Datasets</a>
                        </li>
                        <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:ItemGroupDef">
                            <li class="toc2">
                                <xsl:attribute name="id">
                                    <xsl:value-of select="concat('toc1.', position())"/>
                                </xsl:attribute>
                                <a class="tocItem">
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="concat('#',@OID)"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="concat(@def:Label, ' (', @OID, ')')"/>
                                </a>
                            </li>
                        </xsl:for-each>

                        <!-- **************************************************** -->
                        <!-- ************** Value Level Metadata ************** -->
                        <!-- **************************************************** -->
                        <li id="tocb2.1" class="tocParent" onClick="parentClick('tocb2.1');">
                            <a class="tocItem" href="#valuemeta">Value Level Metadata</a>
                        </li>
                        <xsl:if  test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:ValueListDef">
                            <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:ValueListDef">
                            <!-- Parent Child Start -->
		            <xsl:if  test="not(starts-with(@OID,'ValueList.PP.PPCAT')) and not(starts-with(@OID,'ValueList.CL.CLCAT')) and not(starts-with(@OID,'ValueList.LB.LBCAT'))">
<li class="toc2" >
     <xsl:attribute name="id">
         <xsl:value-of select="concat('tocb2.1.', position())"/>
     </xsl:attribute>
     <a class="tocItem">
         <xsl:attribute name="href">
		#<xsl:value-of select="@OID"/>
							</xsl:attribute>
						   <xsl:value-of select="@OID"/>     
						</a>
				</li>
			   </xsl:if>
			   <xsl:if  test="starts-with(@OID,'ValueList.PP.PPCAT') or starts-with(@OID,'ValueList.CL.CLCAT') or starts-with(@OID,'ValueList.LB.LBCAT')">
		  <xsl:if  test="not(starts-with(@OID,'ValueList.PP.PPCAT.')) and not(starts-with(@OID,'ValueList.CL.CLCAT.')) and not(starts-with(@OID,'ValueList.LB.LBCAT.'))">
		 <li class="toc2" id="tocb2.2" onClick="parentClick('tocb2.2');"> 
		<xsl:attribute name="id">
	<xsl:value-of select="concat('tocb2.1.', position())"/>
	</xsl:attribute>
	<a class="tocItem">
    <xsl:attribute name="href">
	#<xsl:value-of select="@OID"/>
	</xsl:attribute>
<xsl:value-of select="@OID"/>     
	</a>
				 </li>
				  </xsl:if>
				  <xsl:if  test="starts-with(@OID,'ValueList.PP.PPCAT.') or starts-with(@OID,'ValueList.CL.CLCAT.') or starts-with(@OID,'ValueList.LB.LBCAT.')">
					  <li class="toc3"> 
						<xsl:attribute name="id">
								<xsl:value-of select="concat('tocb2.1.', position())"/>
						</xsl:attribute>
							<a class="tocItem">
								<xsl:attribute name="href">
									#<xsl:value-of select="@OID"/>
								</xsl:attribute>
								<xsl:value-of select="@OID"/>     
						</a>
				  </li>
				  </xsl:if>
				</xsl:if>

		            <!-- Parent Child End -->
                            </xsl:for-each>
                        </xsl:if>

                        <!-- **************************************************** -->
                        <!-- ************  Computational Algorithms *********     -->
                        <!-- **************************************************** -->
                        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:ComputationMethod">
                            <li class="toc">
                                <a class="tocItem"  href="#compmethod">Computational Algorithms</a>
                            </li>
                        </xsl:if>

            	        <!-- **************************************************** -->
                        <!-- ************  Controlled Terminology   ************* -->
                        <!-- **************************************************** -->
                        <li id="toc2" class="tocParent" onClick="parentClick('toc2');">
                            <a class="tocItem" href="#decodelist">Controlled Terms</a>
                        </li>

                        <!-- **************************************************** -->
                        <!-- ************  Code list  *************************** -->
                        <!-- **************************************************** -->
                        <li id="toc2.1" class="tocParent2" onClick="parentClick('toc2.1');">
                            <a class="tocItem" href="#decodelist">Code Lists</a>
                        </li>
                        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[not(odm:ExternalCodeList)]">
                            <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[not(odm:ExternalCodeList)]">
                                <li class="toc3">
                                    <xsl:attribute name="id">
                                        <xsl:value-of select="concat('toc2.1.', position())"/>
                                    </xsl:attribute>
                                    <a class="tocItem">
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="concat('#_app_3_', @OID)"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="@Name"/>
                                    </a>
                                </li>
                            </xsl:for-each>
                        </xsl:if>

                        <!-- **************************************************** -->
                        <!-- ************  External Dictionaries  *************** -->
                        <!-- **************************************************** -->
                        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[odm:ExternalCodeList]">
                            <li id="toc2.2" class="tocParent2" onClick="parentClick('toc2.2');">
                                <a class="tocItem" href="#externaldictionary">External Dictionaries</a>
                            </li>
                        </xsl:if>
                        <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[odm:ExternalCodeList]">
                            <li class="toc3">
                                <xsl:attribute name="id">
                                    <xsl:value-of select="concat('toc2.2.', position())"/>
                                </xsl:attribute>
                                <a class="tocItem">
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="concat('#_app_3_',@OID)"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="@Name"/>
                                </a>
                            </li>
                        </xsl:for-each>
                    </ul>
                </div>

                 <!-- **************************************************** -->
                 <!-- *******************  Content  ********************** -->
                 <!-- **************************************************** -->
                <div id="content">
                    <a name="top"/>
                    <br></br>
                    <xsl:apply-templates/>
                </div>
            </body>
        </html>
    </xsl:template>

    <!-- ********************************************************* -->
    <!-- Create the Table Of Contents, define.xml specification    -->
    <!--  Section 2.1.1.                                           -->
    <!-- ********************************************************* -->
    <xsl:template match="/odm:ODM/odm:Study/odm:GlobalVariables"/>
    <xsl:template match="/odm:ODM/odm:Study/odm:MetaDataVersion">
        <table  border='0' cellspacing='1' cellpadding='0' class='newTab'>
            <tr class="mainheader">
                <th colspan='7' align='left' valign='top' height='20'>
                    <xsl:value-of select="concat('Datasets for Study: ',/odm:ODM/odm:Study/odm:GlobalVariables/odm:StudyName)"/>
                </th>
            </tr>
            <font face='Times New Roman' size='2'/>
            <tr align='center' class="subheader">
                <th align='center' valign='bottom'>Dataset</th>
                <th align='center' valign='bottom'>Description</th>
                <th align='center' valign='bottom'>Class</th>
                <th align='center' valign='bottom'>Structure</th>
                <th align='center' valign='bottom'>Purpose</th>
                <th align='center' valign='bottom'>Keys</th>
                <th align='center' valign='bottom'>Location</th>
            </tr>
            <xsl:for-each select="odm:ItemGroupDef">
                <xsl:call-template name="ItemGroupDef"/>
            </xsl:for-each>
        </table>
        <xsl:call-template name="linktop"/>
        <xsl:call-template name="DocGenerationDate"/>

        <!-- **************************************************** -->
        <!-- Create the Data Definition Tables, define.xml        -->
        <!--  specificaiton Section 2.1.2.                        -->
        <!-- **************************************************** -->
        <table  border='0' cellspacing='1' cellpadding='0' width='100%' class='newTab'>
            <xsl:for-each select="odm:ItemGroupDef">
                <xsl:call-template name="ItemRef"/>
            </xsl:for-each>
        </table>
        <xsl:call-template name="linktop"/>
        <xsl:call-template name="DocGenerationDate"/>

        <!-- ****************************************************  -->
        <!-- Create the Value Level Metadata (Value List), define  -->
        <!--  XML specification Section 2.1.4.                     -->
        <!-- ****************************************************  -->
        <xsl:call-template name="AppendixValueList"/>
        <xsl:call-template name="linktop"/>
        <xsl:call-template name="DocGenerationDate"/>

        <!-- ****************************************************  -->
        <!-- Create the Computational Algorithms, define.xml       -->
        <!--  specification Section 2.1.5.                         -->
        <!-- ****************************************************  -->
        <xsl:call-template name="AppendixComputationMethod"/>
        <xsl:call-template name="linktop"/>
        <xsl:call-template name="DocGenerationDate"/>

        <!-- ****************************************************  -->
        <!-- Create the Controlled Terminology (Code Lists),       -->
        <!--  define.xml specification Section 2.1.3.              -->
        <!-- ****************************************************  -->
        <xsl:call-template name="AppendixDecodeList"/>
    </xsl:template>

    <!-- ****************************************************  -->
    <!-- Template: ItemGroupDef                                -->
    <!-- Description: The domain level metadata is represented -->
    <!--   by the ODM ItemGroupDef element                     -->
    <!-- ****************************************************  -->
    <xsl:template name="ItemGroupDef">
        <xsl:variable name="item_OID" select="@ItemOID"/>
        <tr align='left' valign='top'>
            <td>
                <xsl:value-of select="@OID"/>
            </td>
	  <!-- ************************************************************* -->
	  <!-- Link each XPT to its corresponding section in the define      -->
	  <!-- ************************************************************* -->
            <td>
                <a>
                    <xsl:attribute name="href">
                        <xsl:value-of select="concat('#',@OID)"/>
                    </xsl:attribute>
                    <xsl:value-of select="@def:Label"/>
                </a>
            </td>
            <td>
                <xsl:value-of select="@def:Class"/>
            </td>
            <td>
                <xsl:value-of select="@def:Structure"/>
            </td>
            <td>
                <xsl:value-of select="@Purpose"/>&#160;
            </td>
            <td>
                <xsl:value-of select="@def:DomainKeys"/>&#160;
            </td>
            <!-- ************************************************ -->
            <!-- Link each XPT to its corresponding archive file  -->
            <!-- ************************************************ -->
            <td>
                <a>
                    <xsl:attribute name="href">
                        <xsl:value-of select="def:leaf/@xlink:href"/>
                    </xsl:attribute>
                    <xsl:value-of select="def:leaf/def:title"/>
                </a>
            </td>
        </tr>
    </xsl:template>

    <!-- **************************************************** -->
    <!-- Template: ItemRef                                    -->
    <!-- Description: The metadata provided in the Data       -->
    <!--    Definition table is represented using the ODM     -->
    <!--    ItemRef and ItemDef elements                      -->
    <!-- **************************************************** -->
    <xsl:template name="ItemRef">

    <!-- ************************************************************* -->
    <!-- This is the target of the internal xpt name links             -->
    <!-- ************************************************************* -->
        <xsl:variable name="parent_link" select="@OID" />
        <tr class="mainheader">
        <!-- Create the column headers -->
            <th colspan='6' align='left' valign='top' height='20' bgcolor="#ECECEC">
                <a>
                    <xsl:attribute name="Name">
                        <xsl:value-of select="@OID"/>
                    </xsl:attribute>
                </a>
                <!-- try to generate a backlink to the parent domain in case of SUPPXX dataset -->
      		<!-- Remark that this entirely relies on exacts phrasing of 'Supplemental Qualifiers for ' in def:Label -->
                <xsl:choose>
                    <xsl:when test="starts-with(@def:Label,'Supplemental Qualifiers for ')">
                        <xsl:variable name="parentDataset" select="substring(@def:Label,29)"/>
                        <xsl:message>
                            <xsl:value-of select="concat('parentDataset =',$parentDataset)"/>
                        </xsl:message>
                        <xsl:text>Supplemental Qualifiers for </xsl:text>
                        <xsl:element name="a">
                            <xsl:attribute name="href">
                                <xsl:value-of select="concat('#',$parentDataset)"/>
                            </xsl:attribute>
                            <xsl:value-of select="$parentDataset"/>
                        </xsl:element>
                        <xsl:value-of select="concat(' Dataset (',@OID,')')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@def:Label"/>
                        <xsl:value-of select="concat(' Dataset (',@OID,')')"/>
                    </xsl:otherwise>
                </xsl:choose>
                <br/>
            </th>
            <th colspan='1' align='center' bgcolor="#ECECEC">
                <a>
                    <xsl:attribute name="href">
                        <xsl:value-of select="def:leaf/@xlink:href"/>
                    </xsl:attribute>
                    <xsl:value-of select="def:leaf/def:title"/>
                </a>
            </th>
        </tr>
        <font face='Times New Roman' size='2'/>
        <!-- Output the column headers -->
        <tr align='center' class="subheader">
            <th align='center' valign='bottom'>Variable</th>
            <th align='center' valign='bottom'>Label</th>
            <th align='center' valign='bottom'>Type</th>
            <th align='center' valign='bottom'>Controlled Terms or Format</th>
            <th align='center' valign='bottom'>Origin</th>
            <th align='center' valign='bottom'>Role</th>
            <th align='center' valign='bottom'>Comment</th>
        </tr>
        <!-- Get the individual data points -->
        <xsl:for-each select="odm:ItemRef">
            <xsl:variable name="itemDefOid" select="@ItemOID"/>
            <xsl:variable name="itemDef" select="../../odm:ItemDef[@OID=$itemDefOid]"/>
            <tr valign='top'>
                <td>
                   <!-- Hypertext link only those variables that have a value list -->
                    <xsl:choose>
                        <xsl:when test="$itemDef/def:ValueListRef/@ValueListOID!=''">
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="concat('#',$itemDef/def:ValueListRef/@ValueListOID)"/>
                                </xsl:attribute>
                                <xsl:value-of select="$itemDef/@Name"/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$itemDef/@Name"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <a>
                        <xsl:attribute name="Name">
                            <xsl:value-of select="concat($parent_link,'.',$itemDef/@Name)"/>
                        </xsl:attribute>
                    </a>
                </td>
                <td>
                    <xsl:value-of select="$itemDef/@def:Label"/>&#160;
                </td>
                <td align='center'>
                    <xsl:value-of select="$itemDef/@DataType"/>&#160;
                </td>
                <td>
                    <!-- generate a temporary variable taht contains the OID of the CodeList -->
                    <xsl:variable name="CODE" select="$itemDef/odm:CodeListRef/@CodeListOID"/>
                    <!-- and a temporary variable that contains the NODE with that OID -->
                    <xsl:variable name="CodeListDef" select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[@OID=$CODE]"/>
                    <!-- ************************************************************** -->
                    <!-- Hypertext Link to the Decode Appendix when the codelist exists -->
                    <!-- ************************************************************** -->
                    <xsl:choose>
                        <xsl:when test="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[@OID=$CODE]">
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="concat('#_app_3_',$CodeListDef/@OID)"/>
                                </xsl:attribute>
                                <xsl:value-of select="$CodeListDef/@OID"/>
                            </a>
                        </xsl:when>
			<!-- CodeList could not be found: just display the OID
			P.S. This case would be a violation of the standard -->
                        <xsl:otherwise>
                            <xsl:value-of select="$itemDef/odm:CodeListRef/@CodeListOID"/>&#160;
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- When the datatype is 'date', 'time' or 'datetime'
                    or it is a -DUR (duration) variable, print 'ISO8601' in this column -->
                    <xsl:if test="$itemDef/@DataType='date' or $itemDef/@DataType='time' or $itemDef/@DataType='datetime' or substring($itemDef/@Name,string-length($itemDef/@Name)-2,string-length($itemDef/@Name)) = 'DUR'">ISO8601</xsl:if>
                </td>

		<!-- *************************************************** -->
		<!-- Origin Column                                       -->
		<!-- *************************************************** -->
                <td style="white-space:nowrap;">
                    <xsl:choose>
                        <xsl:when test="contains($itemDef/@Origin,'CRF Pages')">
                            <xsl:value-of select="substring-before($itemDef/@Origin,'CRF Pages ')"/>
                            <xsl:text> CRF Pages </xsl:text>
                            <xsl:call-template name="crfpage">
                                <xsl:with-param name="pages" select="concat(substring-after($itemDef/@Origin,'CRF Pages '),',')"/>
                            </xsl:call-template>
                        </xsl:when>

                        <xsl:when test="contains($itemDef/@Origin,'-CRF Pages')">
                            <xsl:call-template name="crfpage2">
                                <xsl:with-param name="pages" select="$itemDef/@Origin"/>
                            </xsl:call-template>
                        </xsl:when>

                        <xsl:when test="contains($itemDef/@Origin,'-CRF Page')">
                            <xsl:call-template name="crfpage2">
                                <xsl:with-param name="pages" select="$itemDef/@Origin"/>
                            </xsl:call-template>
                        </xsl:when>

                        <xsl:when test="contains($itemDef/@Origin,'-CRF')">
                            <xsl:call-template name="crfpage2">
                                <xsl:with-param name="pages" select="$itemDef/@Origin"/>
                            </xsl:call-template>
                        </xsl:when>

                        <xsl:when test="contains($itemDef/@Origin,'CRF Page ')">
                            <xsl:value-of select="substring-before($itemDef/@Origin,'CRF Page ')"/>
                            <xsl:text>CRF Page </xsl:text>
                            <xsl:call-template name="crfpage">
                                <xsl:with-param name="pages" select="concat(substring-after($itemDef/@Origin,'CRF Page '),',')"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <xsl:otherwise>
                            <xsl:value-of select="$itemDef/@Origin"/>&#160;
                        </xsl:otherwise>
                    </xsl:choose>
                </td>

                <!-- *************************************************** -->
                <!-- Role Column                                         -->
                <!-- *************************************************** -->
                <td>
                    <xsl:variable name="ROLECODE" select="'ROLECODELIST'"/>
                    <xsl:variable name="RoleCodeListDef" select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[@OID=$ROLECODE]"/>
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="concat('#_app_3_',$RoleCodeListDef/@OID)"/>
                        </xsl:attribute>
                        <xsl:value-of select="@Role"/>
                    </a>
                </td>

                <!-- *************************************************** -->
                <!-- Comments                                            -->
                <!-- *************************************************** -->
                <td>
                    <!-- create a hyperlink to a 'Notes' document - case: several notes -->
                    <!-- REMARK: this STRICTLY relies on the text 'See Notes ' (CASE-SENSITIVE !!!)
                    being present in the 'Comment' attribute on the ItemDef -->
                    <xsl:choose>
                        <xsl:when test="contains($itemDef/@Comment,'See Notes')">
                            <xsl:value-of select="substring-before($itemDef/@Comment,'See Notes ')"/>
                            <xsl:text> See Notes </xsl:text>
                            <xsl:call-template name="seenote">
                                <xsl:with-param name="notes" select="concat(substring-after($itemDef/@Comment,'See Notes '),',')"/>
                            </xsl:call-template>
                        </xsl:when>
               		<!-- create a hyperlink to a 'Notes' document - case: single note -->
               		<!-- REMARK: this STRICTLY relies on the text 'See Note ' (CASE-SENSITIVE !!!)
        		being present in the 'Comment' attribute on the ItemDef -->
                        <xsl:when test="contains($itemDef/@Comment,'See Note ')">
                            <xsl:value-of select="substring-before($itemDef/@Comment,'See Note ')"/>
                            <xsl:text>See Note </xsl:text>
                            <xsl:call-template name="seenote">
                                <xsl:with-param name="notes" select="concat(substring-after($itemDef/@Comment,'See Note '),',')"/>
                            </xsl:call-template>
                        </xsl:when>
               		<!-- All other cases: simply copy the text from the 'Comment' attribute -->
                        <xsl:otherwise>
                            <xsl:value-of select="$itemDef/@Comment"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="$itemDef/@def:ComputationMethodOID">
                        <br/>
                        <xsl:text>See Computational Method: </xsl:text>
                        <a>
                            <xsl:attribute name="href">
                                <xsl:value-of select="concat('#',$itemDef/@def:ComputationMethodOID)"/>
                            </xsl:attribute>
                            <xsl:value-of select="$itemDef/@def:ComputationMethodOID"/>
                        </a>
                    </xsl:if>
                </td>
            </tr>
        </xsl:for-each>

        <!-- *************************************************** -->
 	<!-- Link to SUPPXX domain                               -->
	<!-- For those domains with Suplemental Qualifiers       -->
	<!-- *************************************************** -->

	<!-- REMARK that we are still in the 'ItemRef' template
	but at the 'ItemGroupDef' level -->
        <xsl:variable name="datasetName" select="@Name"/>
        <xsl:variable name="suppDatasetName" select="concat('SUPP',$datasetName)"/>
	<!-- create an extra row to the SUPPXX dataset when there is one -->
        <xsl:if test="../odm:ItemGroupDef[@Name=$suppDatasetName]">
            <tr>
                <th colspan='7' align='left' valign='top' height='20'>
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="concat('#',$suppDatasetName)"/>
                        </xsl:attribute>
                        <xsl:value-of select="concat(' Supplemental Qualifier Dataset( ',$suppDatasetName,')')"/>
                    </a>
                </th>
            </tr>
        </xsl:if>
    </xsl:template>

   <!-- *************************************************************** -->
   <!-- Template: AppendixValueList                                     -->
   <!-- Description: This template creates the define.xml specification -->
   <!--   Section 2.1.4: Value Level Metadata (Value List)              -->
   <!-- ****  1. Create atable for each ValueList category ***** -->
   <!-- ****  2. Add QSCAT as a category to ValueList ***** -->
   <!-- ****  3. Link to the top of each table of ValueList categories ***** -->
   <!-- *************************************************************** -->
    <xsl:template name="AppendixValueList">
        <a name='valuemeta'/>
        <table  border='0' cellspacing='1' cellpadding='0' class='newTab'>
            <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:ValueListDef">
                <tr class="mainheader">
                    <th colspan='9' align='left' valign='top' height='20'>
                        <!-- Create an anchor -->
                        <xsl:variable name="listtype" select="@OID"/>
                        <a>
                            <xsl:attribute name="Name">
                                <xsl:value-of select="concat('#',@OID)"/>
                            </xsl:attribute>&#160;
                        </a>
                        <b>
                            <xsl:value-of select="@Name"/>
                            <xsl:value-of select="concat('Value Level Metadata (',@OID,')')"/>
                        </b>
                    </th>
                </tr>
                <font face='Times New Roman' size='2'/>
                <tr align='center' bgcolor="#00ffff">
                    <th align='center' valign='bottom'>Source Variable</th>
                    <th align='center' valign='bottom'>Value</th>
                    <th align='center' valign='bottom'>Label</th>
                    <th align='center' valign='bottom'>Type</th>
                    <th align='center' valign='bottom'>Controlled Terms or Format</th>
                    <th align='center' valign='bottom'>Origin</th>
                    <th align='center' valign='bottom'>Role</th>
                    <th align='center' valign='bottom'>Comment</th>
                </tr>
                <!-- Get the individual data points -->
                <xsl:for-each select="./odm:ItemRef">
                    <xsl:variable name="valueDefOid" select="@ItemOID"/>
                    <xsl:variable name="role" select="@Role"/>
                    <xsl:variable name="valueDef" select="../../odm:ItemDef[@OID=$valueDefOid]"/>
                    <xsl:variable name="parentOID" select="../@OID"/>
                    <xsl:variable name="parentDef" select="../../odm:ItemDef/def:ValueListRef[@ValueListOID=$parentOID]"/>
                    <xsl:variable name="qsCat" select="ValueList.QS.QSCAT."/>
                    <xsl:variable name="valueMeta" select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:ValueListDef"/>
                    <tr>
                        <td>
                        <!-- Parent Child Start -->
                           <xsl:if  test="not(starts-with($valueDefOid,'PP.PPCAT.')) and not(starts-with($valueDefOid,'CL.CLCAT.')) and not(starts-with($valueDefOid,'LB.LBCAT.'))">
		          <a>
                  <xsl:attribute name="Name">
                    <xsl:value-of select="$parentOID"/>
                  </xsl:attribute>
                </a>
                <xsl:value-of select="$parentDef/../@Name"/>
              </xsl:if>
	<xsl:if  test="starts-with($valueDefOid,'PP.PPCAT')">
				<xsl:choose>
				<xsl:when test="$valueDef/def:ValueListRef/@ValueListOID!=''">
					PPCAT
				</xsl:when>
				<xsl:otherwise>
					PPTESTCD
				</xsl:otherwise>
				</xsl:choose>
				</xsl:if>
<xsl:if  test="starts-with($valueDefOid,'CL.CLCAT')">
				<xsl:choose>
				<xsl:when test="$valueDef/def:ValueListRef/@ValueListOID!=''">
					CLCAT
				</xsl:when>
				<xsl:otherwise>
					CLTESTCD
				</xsl:otherwise>
				</xsl:choose>
				</xsl:if>
<xsl:if  test="starts-with($valueDefOid,'LB.LBCAT')">
				<xsl:choose>
				<xsl:when test="$valueDef/def:ValueListRef/@ValueListOID!=''">
					LBCAT
				</xsl:when>
				<xsl:otherwise>
					LBTESTCD
				</xsl:otherwise>
				</xsl:choose>
				</xsl:if>


                        <!-- Parent Child End -->
                        </td>
                        <td>
                            <!-- Hypertext link only those variables that have a value list  -->
                            <xsl:choose>
                                <xsl:when test="$valueDef/def:ValueListRef/@ValueListOID!=''">
                                    <a>
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="concat('#',$valueDef/def:ValueListRef/@ValueListOID)"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="$valueDef/@Name"/>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$valueDef/@Name"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </td>
                        <td>
                            <xsl:value-of select="$valueDef/@def:Label"/>&#160;
                        </td>
                        <td align='center'>
                            <xsl:value-of select="$valueDef/@DataType"/>&#160;
                        </td>
                        <td>
                        <!-- *************************************************** -->
                        <!-- Hypertext Link to the Decode Appendix               -->
                        <!-- *************************************************** -->
                            <xsl:choose>
                                <xsl:when test="$valueDef/odm:CodeListRef/@CodeListOID!=''">
                                    <a>
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="concat('#_app_3_',$valueDef/odm:CodeListRef/@CodeListOID)"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="$valueDef/odm:CodeListRef/@CodeListOID"/>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$valueDef/odm:CodeListRef/@CodeListOID"/>&#160;
                                </xsl:otherwise>
                            </xsl:choose>
                        </td>
                        <!-- *************************************************** -->
                        <!-- Origin Column                                       -->
                        <!-- *************************************************** -->
                        <td style="white-space:nowrap;">
                            <xsl:choose>
                                <xsl:when test="contains($valueDef/@Origin,'CRF Pages')">
                                    <xsl:value-of select="substring-before($valueDef/@Origin,'CRF Pages ')"/>
                                    <xsl:text>CRF Pages </xsl:text>
                                    <xsl:call-template name="crfpage">
                                        <xsl:with-param name="pages" select="concat(substring-after($valueDef/@Origin,'CRF Pages '),',')"/>
                                    </xsl:call-template>
                                </xsl:when>

                                <xsl:when test="contains($valueDef/@Origin,'-CRF ')">
                                    <xsl:call-template name="crfpage2">
                                        <xsl:with-param name="pages" select="$valueDef/@Origin"/>
                                    </xsl:call-template>
                                </xsl:when>

                                <xsl:when test="contains($valueDef/@Origin,'CRF Page ')">
                                    <xsl:value-of select="substring-before($valueDef/@Origin,'CRF Page ')" />
                                    <xsl:text>CRF Page </xsl:text>
                                    <xsl:call-template name="crfpage">
                                        <xsl:with-param name="pages" select="concat(substring-after($valueDef/@Origin,'CRF Page '),',')"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$valueDef/@Origin"/>&#160;
                                </xsl:otherwise>
                            </xsl:choose>
                        </td>
                        <td>
                            <xsl:variable name="ROLECODE" select="'ROLECODELIST'"/>
                            <xsl:variable name="RoleCodeListDef" select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[@OID=$ROLECODE]"/>
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="concat('#_app_3_',$RoleCodeListDef/@OID)"/>
                                </xsl:attribute>
                                <xsl:value-of select="$role"/>
                            </a>
                        </td>
                        <td>
                            <!-- Case that the Comment attribute contains the wording
         			'See Notes' (CASE-SENSITIVE !)
         			then create a set of hyperlinks -->
                            <xsl:choose>
                                <xsl:when test="contains($valueDef/@Comment,'See Notes')">
                                    <xsl:value-of select="substring-before($valueDef/@Comment,'See Notes ')"/>
                                    <xsl:text>See Notes </xsl:text>
                                    <xsl:call-template name="seenote">
                                        <xsl:with-param name="notes" select="concat(substring-after($valueDef/@Comment,'See Notes '),',')"/>
                                    </xsl:call-template>
                                </xsl:when>
            		
                                <!-- Case that the Comment attribute contains the wording
                                    'See Note ' (CASE-SENSITIVE !)
                                    then create a single hyperlink -->
                                <xsl:when test="contains($valueDef/@Comment,'See Note ')">
                                    <xsl:value-of select="substring-before($valueDef/@Comment,'See Note ')" />
                                    <xsl:text>See Note </xsl:text>
                                    <xsl:call-template name="seenote">
                                        <xsl:with-param name="notes" select="concat(substring-after($valueDef/@Comment,'See Note '),',')"/>
                                    </xsl:call-template>
                                </xsl:when>
				
                                <!-- All other cases: just copy the contents of the 'Comment' attribute -->
                                <xsl:otherwise>
                                    <xsl:value-of select="$valueDef/@Comment"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            
                            <xsl:if test="$valueDef/@def:ComputationMethodOID">
                                <br/>
                                <xsl:text>See Computational Method: </xsl:text>
                                <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="concat('#',$valueDef/@def:ComputationMethodOID)"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="$valueDef/@def:ComputationMethodOID"/>
                                </a>
                            </xsl:if>
                        </td>
                    </tr>
                </xsl:for-each>

                <!-- ***************************************************  -->
                <!-- Link back to the dataset from QNAM                      -->
                <!-- For those domains with Suplemental Qualifiers -->
                <!-- ***************************************************  -->

                <xsl:variable name="Itemg" select="/odm:ODM/odm:Study/odm:MetaDataVersion/ItemGroupDef"/>
                <xsl:variable name="ItemgOID" select="@OID"/>
                <xsl:variable name="Suppitem" select="substring($ItemgOID,15,2 )"/>
                <xsl:if  test="starts-with($ItemgOID,'ValueList.SUPP')">
                    <!-- we are still at the ValueListDef level -->
                    <xsl:for-each select="../odm:ItemDef[def:ValueListRef/@ValueListOID = $ItemgOID]">
                        <!-- there should be only one -->
                        <xsl:variable name="itemdefoid" select="@OID"/>
                        <!-- now get the domains that reference this Item -->
                        <xsl:for-each select="//odm:ItemGroupDef[odm:ItemRef/@ItemOID = $itemdefoid]">
                            <xsl:variable name="datasetname" select="substring(@OID,5)"/>
                            <tr class="subheader">
                                <th colspan='8' align='left' valign='top' height='20'>
                                    <a>
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="concat('#',$datasetname)"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="concat(' Dataset (',$datasetname,')')"/>
                                    </a>
                                </th>
                            </tr>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </table>
    </xsl:template>

    <!-- *************************************************************** -->
    <!-- Template: AppendixComputationMethod                             -->
    <!-- Description: This template creates the define.xml specification -->
    <!--   Section 2.1.5: Computational Algorithms                       -->
    <!-- *************************************************************** -->
    <xsl:template name="AppendixComputationMethod" >
        <a name='compmethod'/>
        <table  border='0' cellspacing='1' cellpadding='0' class='newTab'>
            <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:ComputationMethod">
                <tr class="mainheader">
                    <th colspan='2' align='left' valign='top' height='20' bgcolor="#ECECEC">
                        <!-- Create an anchor -->
                        <xsl:variable name="listtype" select="@OID"/>
                        <a>
                            <xsl:attribute name="Name">
                                <xsl:value-of select="concat('#',@OID)"/>
                            </xsl:attribute>&#160;
                        </a>
                        <b>
                            <xsl:value-of select="concat(@Name,' Computational Algorithms (', @OID,')')"/>
                        </b>
                    </th>
                </tr>
                <font face='Times New Roman' size='2'/>
                <tr align='center' bgcolor="#00ffff">
                    <th>Reference Name</th>
                    <th>Computation Method</th>
                </tr>
                <tr align='left'>
                    <td>
                        <!-- Create an anchor -->
                        <a>
                            <xsl:attribute name="Name">
                                <xsl:value-of select="@OID"/>
                            </xsl:attribute>
                        </a>
                        <xsl:value-of select="@OID"/>
                    </td>
                    <td>
                        <xsl:value-of select="."/>
                    </td>
                </tr>
            </xsl:for-each>
        </table>
    </xsl:template>

    <!-- *************************************************************** -->
    <!-- Template: AppendixDecodeList                                    -->
    <!-- Description: This template creates the define.xml specification -->
    <!-- Section 2.1.3: Controlled Terminology (Code Lists)            -->
    <!-- *************************************************************** -->
    <xsl:template name="AppendixDecodeList">
        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[not(odm:ExternalCodeList)]">
            <a name='decodelist'/>
            <table  border='0' cellspacing='1' cellpadding='0' class='newTab'>
                <tr class="mainheader">
                    <th colspan='2' align='left' valign='top' height='20'>Controlled Terminology (Code Lists)</th>
                </tr>
                <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[not(odm:ExternalCodeList)]">
                    <tr align='center' class="subheader">
                        <td colspan='2'>
                            <!-- Create an anchor -->
                            <xsl:variable name="listtype" select="@OID"/>
                            <a>
                                <xsl:attribute name="Name">
                                    <xsl:value-of select="concat('_app_3_',@OID)"/>
                                </xsl:attribute>&#160;
                            </a>
                            <b>
                                <xsl:value-of select="concat(@Name,', Reference Name (',@OID,')')"/>
                            </b>
                        </td>
                    </tr>
                    <font face='Times New Roman' size='2'/>
                    <tr align='center' bgcolor="#00ffff">
                        <th>Code Value</th>
                        <th>Code Text </th>
                    </tr>
                    <xsl:for-each select="./odm:CodeListItem">
                        <xsl:sort data-type="number" select="@def:Rank" order="ascending"/>
                        <tr>
                            <td>
                                <xsl:value-of select="@CodedValue"/>
                            </td>
                            <td>
                                <xsl:value-of select="./odm:Decode/odm:TranslatedText"/>
                            </td>
                        </tr>
                    </xsl:for-each>
                </xsl:for-each>
            </table>

            <xsl:call-template name="linktop"/>
            <xsl:call-template name="DocGenerationDate"/>
        </xsl:if>

        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[odm:ExternalCodeList]">
            <a name='externaldictionary'/>
            <table  border='0' cellspacing='1' cellpadding='0' class='newTab'>
                <tr class="mainheader">
                    <th colspan='2' align='left' valign='top' height='20' bgcolor="#ECECEC">
                        Controlled Terminology (External Dictionaries)
                    </th>
                </tr>
                <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:CodeList[odm:ExternalCodeList]">
                    <tr align='center'>
                        <td colspan='2'>
                            <!-- Create an anchor -->
                            <xsl:variable name="listtype" select="@OID"/>
                            <a>
                                <xsl:attribute name="Name">
                                    <xsl:value-of select="concat('_app_3_',@OID)"/>
                                </xsl:attribute>&#160;
                            </a>
                            <b>
                                <xsl:value-of select="concat(@Name,', Reference Name (',@OID,')')"/>
                            </b>
                        </td>
                    </tr>
                    <font face='Times New Roman' size='2'/>
                    <tr align='center' bgcolor="#00ffff">
                        <th>External Dictionary</th>
                        <th>Dictionary Version</th>
                    </tr>
                    <xsl:for-each select="./odm:ExternalCodeList">
                        <tr>
                            <td>
                                <xsl:value-of select="@Dictionary"/>
                            </td>
                            <td>
                                <xsl:value-of select="@Version"/>
                            </td>
                        </tr>
                    </xsl:for-each>
                </xsl:for-each>
            </table>

            <xsl:call-template name="linktop"/>
            <xsl:call-template name="DocGenerationDate"/>
        </xsl:if>
    </xsl:template>

    <!-- ************************************************************* -->
    <!-- Template: AnnotatedCRF                                        -->
    <!-- Description: This template creates CRF hypertexted footnote   -->
    <!-- ************************************************************* -->
    <xsl:template name="AnnotatedCRF">
        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:AnnotatedCRF">
            <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:AnnotatedCRF/def:DocumentRef">
                <xsl:variable name="leafIDs" select="@leafID"/>
                <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafIDs]"/>
                <p align="left">
                    <xsl:value-of select="$leaf/def:title"/>
                    <xsl:text>(</xsl:text>
                    <a target="_blank">
                        <xsl:attribute name="href">
                            <xsl:value-of select="$leaf/@xlink:href"/>
                        </xsl:attribute>
                        <xsl:value-of select="$leaf/@xlink:href"/>
                    </a>
                    <xsl:text>)</xsl:text>
                </p>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- ************************************************************* -->
    <!-- Template: SupplimentalDataDefinitionDoc                       -->
    <!-- Description: This template creates the hypertexted footnote   -->
    <!-- ************************************************************* -->
    <xsl:template name="SupplimentalDataDefinitionDoc">
        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:SupplementalDoc">
            <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:SupplementalDoc/def:DocumentRef">
                <xsl:variable name="leafIDs" select="@leafID"/>
                <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafIDs]"/>
                <p align="left">
                    <xsl:value-of select="$leaf/def:title"/>
                    <xsl:text>(</xsl:text>
                    <a target="_blank">
                        <xsl:attribute name="href">
                            <xsl:value-of select="$leaf/@xlink:href"/>
                        </xsl:attribute>
                        <xsl:value-of select="$leaf/@xlink:href"/>
                    </a>
                    <xsl:text>)</xsl:text>
                </p>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- ************************************************************* -->
    <!-- Template: linktop                                             -->
    <!-- Description: This template creates the hypertexted footnote   -->
    <!-- ************************************************************* -->
    <xsl:template name="linktop">
        <p style="margin-left:10px;" align='left'>
            <xsl:text>Go to the top of the </xsl:text>
            <a href="#TOP">define.xml</a>
        </p>
        <p style="margin-left:10px;" align='left'>
	    <!-- ==================================================== -->
            <!-- ================ Annotated CRF ===================== -->
            <!-- ==================================================== -->
            <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:AnnotatedCRF">
                <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:AnnotatedCRF/def:DocumentRef">
                    <xsl:variable name="leafIDs" select="@leafID"/>
                    <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafIDs]"/>
                    <a target="_blank">
                        <xsl:attribute name="href">
                            <xsl:value-of select="$leaf/@xlink:href"/>
                        </xsl:attribute>
                        <xsl:value-of select="$leaf/def:title"/>
                    </a>
                </xsl:for-each>
            </xsl:if>
        </p>
        <p style="margin-left:10px;" align='left'>
            <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:SupplementalDoc">
                <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:SupplementalDoc/def:DocumentRef">
                    <xsl:variable name="leafIDs" select="@leafID"/>
                    <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafIDs]"/>
                    <a target="_blank">
                        <xsl:attribute name="href">
                            <xsl:value-of select="$leaf/@xlink:href"/>
                        </xsl:attribute>
                        <xsl:value-of select="$leaf/def:title"/>
                    </a>
                </xsl:for-each>
            </xsl:if>
        </p>
    </xsl:template>

    <!-- ************************************************************* -->
    <!-- Template: DocGenerationDate                                   -->
    <!-- Description: This template creates the Document Date footnote -->
    <!-- ************************************************************* -->
    <xsl:template name="DocGenerationDate">
        <p style="margin-left:10px;" align='left'>
			 <xsl:value-of select="concat('Date of document generation (', /odm:ODM/@CreationDateTime,')')"/>
        </p>
        <br/>
        <br/>
    </xsl:template>

    <!-- =================================================== -->
    <!-- Hypertext Link to CRF Pages (if necessary)          -->
    <!-- =================================================== -->
    <xsl:template name="crfpage">
        <xsl:param name="pages"/>
        <xsl:variable name="first-page" select="substring-before($pages,',')"/>
        <xsl:variable name="rest-of-pages" select="substring-after($pages,', ')"/>
        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:AnnotatedCRF">
            <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:AnnotatedCRF/def:DocumentRef">
                <xsl:variable name="leafIDs" select="@leafID"/>
                <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafIDs]"/>
                <a target="_blank">
                    <xsl:attribute name="href">
                        <xsl:value-of select="concat($leaf/@xlink:href,'#page=',$first-page)"/>
                    </xsl:attribute>
                    <xsl:value-of select="$first-page"/>
                </a>
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="$rest-of-pages">
            <xsl:text>,&#160;</xsl:text>
            <xsl:call-template name="crfpage">
                <xsl:with-param name="pages" select="$rest-of-pages"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- =================================================== -->
    <!-- Hypertext Link to CRF Pages 2 (if necessary)          -->
    <!-- =================================================== -->
    <xsl:template name="crfpage2">
        <xsl:param name="pages"/>
        <xsl:variable name="first-string" select="substring-before($pages,';')"/>
        <xsl:variable name="rest-of-string" select="substring-after($pages,';')"/>
        <xsl:variable name="first-text" select="concat(substring-before($first-string,'-'),'-CRF Page ')"/>
        <xsl:variable name="first-pages" select="substring-after($first-string,$first-text)"/>
        <xsl:variable name="first-page" select="$first-pages"/>

        <xsl:if  test="contains($first-page,',')" >
            <xsl:value-of select="$first-text"/>
            <xsl:call-template name="crfpage">
                <xsl:with-param name="pages" select="concat($first-page,',')"/>
            </xsl:call-template>
        </xsl:if>

        <xsl:if  test="(not(contains($first-page,',')))">
            <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:AnnotatedCRF">
                <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:AnnotatedCRF/def:DocumentRef">
                    <xsl:variable name="leafIDs" select="@leafID"/>
                    <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafIDs]"/>
                    <xsl:value-of select="$first-text"/>
                    <a target="_blank">
                        <xsl:attribute name="href">
                            <xsl:value-of select="concat($leaf/@xlink:href,'#page=',$first-page)"/>
                        </xsl:attribute>
                        <xsl:value-of select="$first-page"/>
                    </a>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>

        <xsl:if test="$rest-of-string">
            <xsl:text> </xsl:text>
            <xsl:call-template name="crfpage2">
                <xsl:with-param name="pages" select="$rest-of-string"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- =================================================== -->
    <!-- Hypertext Link to Supplemental Doc (if necessary)   -->
    <!-- =================================================== -->
    <xsl:template name="seenote">
        <xsl:param name="notes"/>
        <xsl:variable name="first-note" select="substring-before($notes,',')"/>
        <xsl:variable name="rest-of-notes" select="substring-after($notes,', ')"/>
        <!-- find the corresponding def:SupplementalDoc -->
        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:SupplementalDoc">
            <!-- we use xsl:for-each though there should only be one -->
            <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/def:SupplementalDoc/def:DocumentRef">
      		<!-- and the corresponding def:leaf -->
                <xsl:variable name="leafIDs" select="@leafID"/>
                <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafIDs]"/>
		<!-- create the hyperlink itself -->
                <a target="_blank">
                    <xsl:if test="contains($leafIDs,'ReviewersGuide')">
                        <xsl:attribute name="href">
                            <xsl:value-of select="concat($leaf/@xlink:href,'#nameddest=',$first-note)"/>
                        </xsl:attribute>
                        <xsl:value-of select="$first-note"/>
                    </xsl:if>
                </a>
            </xsl:for-each>
        </xsl:if>
	<!-- this part works recursively,
             it takes the  remaining list of note numbers (e.g. 3, 5, 11),
             creates the hyperlink for the first one (note 3 in this case),
             and then calls the parent template with the list of remaining notes after the first one (i.e. 5, 11).
             Like that, a hyperlink is created for each note in the list -->
        <xsl:if test="$rest-of-notes">
            <xsl:text>, </xsl:text>
            <xsl:call-template name="seenote">
                <xsl:with-param name="notes" select="$rest-of-notes"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
