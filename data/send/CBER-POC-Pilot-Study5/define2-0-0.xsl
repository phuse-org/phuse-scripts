<?xml version="1.0" encoding="utf-8"?>
<!--

  The MIT License (MIT) 
  
  Copyright (c) 2013-2018 Lex Jansen
  
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
  associated documentation files (the "Software"), to deal in the Software without restriction, 
  including without limitation the rights to use, copy, modify, merge, publish, distribute, 
  sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
  furnished to do so, subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all copies or 
  substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
  NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
  OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:odm="http://www.cdisc.org/ns/odm/v1.3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:def="http://www.cdisc.org/ns/def/v2.0" xmlns:xlink="http://www.w3.org/1999/xlink" 
  xmlns:arm="http://www.cdisc.org/ns/arm/v1.0" xml:lang="en"
  exclude-result-prefixes="def xlink odm xsi arm">
  <xsl:output method="html" indent="no" encoding="utf-8" 
    doctype-system="http://www.w3.org/TR/html4/strict.dtd"
    doctype-public="-//W3C//DTD HTML 4.01//EN" version="4.0"/>


  <!-- ********************************************************************************************************* -->
  <!-- Stylesheet Parameters - These parameters can be set in the XSLT processor.                                -->
  <!-- ********************************************************************************************************* -->

  <!-- Number of CodeListItems to display in Controlled Terms or Format column (default=5) 
       To display all CodeListItems, specify 999; to display no CodeListItems, specify 0. -->
  <xsl:param name="nCodeListItemDisplay" select="5"/>
  
  <!-- Display Methods table (0/1)? -->
  <xsl:param name="displayMethodsTable" select="1"/>

  <!-- Display Comments table (0/1)? -->
  <xsl:param name="displayCommentsTable" select="0"/>

  <!-- Display Prefixes ([Comment], [Method], [Origin]) (0/1)? -->
  <xsl:param name="displayPrefix" select="0" />
  
  <!-- Display Length, DisplayFormat and Significant Digits (0/1)? -->
  <xsl:param name="displayLengthDFormatSD" select="0" />
  
  <!-- ********************************************************************************************************* -->
  <!-- File:        define2-0.xsl                                                                                -->
  <!-- Description: This stylesheet works with the Define-XML 2.0.x specification, including the Analysis        -->
  <!--              Results Metadata v1.0 extension.                                                             -->
  <!-- Author:      Lex Jansen, CDISC Data Exchange Standards Team                                               -->
  <!--                                                                                                           -->  
  <!-- Changes:                                                                                                  -->
  <!--   2018-11-21 - Code cleanup                                                                               -->
  <!--   2018-10-24 - Added PublishingSet to Standard display in CodeLists (Draft Define-XML 2.1)                -->
  <!--   2018-08-09 - Fixed issue when there is no ItemGroupDef/@def:ArchiveLocationID                           -->
  <!--   2018-07-24 - Change Derivation to Method                                                                -->
  <!--              - Added tags for unresolved references                                                       -->
  <!--              - Always use Name attribute in Datasets table and header row (instead of SASDatasetName)     -->
  <!--              - Show pointer for cursor for VLM hyperlinks and buttons to show they are clickable objects  -->
  <!--              - Fix bug  to allow Supplemental variable keys to be mid key-order, not just at the end      -->
  <!--                Also fixed this for AP domains that have SQ supplemental variables.                        -->
  <!--              - Use Name rather than SASDatasetName for consistency.                                       -->
  <!--   2018-04-20 - Removed def:Standard/IsDefault (Draft Define-XML 2.1)                                      -->
  <!--              - Added CodeList/def:IsNonStandard (Draft Define-XML 2.1)                                    -->
  <!--   2018-03-01 - Made ARM table background consistent with other tables.                                    -->
  <!--              - Restored separation line in ARM summary listing.                                           -->
  <!--              - Added more vertical spacing between Expand All/Collapse All VLM buttons.                   -->
  <!--              - Fixed bug where only one FormalExpression element was supported per MethodDef element.     -->
  <!--              - Changed LE and GE comparators to use Unicode &#x2264 and &#x2265.                          -->
  <!--              - Made links from datasets in ARM consistent. Both will now go to the summary dataset table. -->
  <!--   2018-02-26 - Added version 2.1 comments.                                                                -->
  <!--              - Improved Expand All/Collapse All VLM buttons rounded corners.                              -->
  <!--   2018-02-16 - Added Class/SubClass (Draft Define-XML 2.1)                                                --> 
  <!--   2018-02-13 - Improved Expand All/Collapse All VLM buttons.                                              -->
  <!--   2018-01-30 - Change Expand All/Collapse All VLM to buttons.                                             -->
  <!--   2018-01-25 - Give VLM rows the same background color as governing row.                                  -->
  <!--              - Some label updates.                                                                        -->
  <!--   2017-12-27 - Add Condition column only when there is VLM.                                               -->
  <!--              - Collapse/expand VLM rows.                                                                  -->
  <!--   2017-12-06 - Sort ItemRefs in VLM by OrderNumber.                                                       -->
  <!--   2017-11-20 - Further tweaking of VLM within dataset variable tables, including nested VLM for SuppQuals.-->
  <!--              - Fixed collapsed study metadata display when an  attribute is empty.                        -->
  <!--   2017-11-20 - Initial implementation of VLM within dataset variable tables (no nested VLM yet).          -->
  <!--   2017-10-23 - Support for CodeListItem/Description and EnumeratedItem/Description (Draft Define-XML 2.1) -->
  <!--              - Support for Associated Persons Supplemental Qualifiers.                                    -->
  <!--   2017-08-28 - Small fixes: ISO8601 -> ISO 8601, No data -> No Data, NonStandard -> Non Standard.         -->
  <!--   2017-08-02 - Removed display of OIDs from CodeList tables.                                              -->
  <!--   2017-08-01 - Fixed display for named destination with '#20' (blank).                                    -->
  <!--   2017-07-31 - Fixed link to XPT transport files (/ItemGroupDef/def:leaf) to open external.               -->
  <!--              - Removed link to related dataset from the bottom of the table.                              -->
  <!--              - Improved breaks in composite WhereClause display.                                          -->
  <!--              - Added non-breaking space to codelist item display in variable table, which improves break. -->
  <!--              - Fixed linking to items in WhereClause that do not belong to the current ItemGroup, which   -->
  <!--                will only work for items that are referenced in an ItemGroup and can uniquely be found.    -->
  <!--   2017-07-23 - Improved display for VLM for SuppQuals.                                                    -->
  <!--   2017-07-21 - Added support for multiple destinations in a def:PDFPageRef/PageRefs attribute.            -->
  <!--   2017-07-17 - Added display of:                                                                          -->
  <!--                  ItemGroupDef/def:HasNoData, ItemRef/def:HasNoData (Draft Define-XML 2.1)                 -->
  <!--              - Added display of ItemRef/@Role in variable tables and VLM tables, when defined.            -->
  <!--              - Completed display of document references.                                                  -->
  <!--   2017-07-07 - Display round brackets with multiple def:WhereClauseRefs.                                  -->
  <!--   2017-06-19 - Consistency between SDS and ADaM.                                                          -->
  <!--   2017-06-05 - Changed displayCommentsTable parameter default to 0.                                       -->
  <!--   2017-05-23 - Added display of key variables as defined in SUPPxx datasets.                              -->
  <!--   2017-05-19 - Added display of ODM/@Context.                                                             -->
  <!--              - Added display of CodeListItem/@Rank and odm:EnumeratedItem/@Rank.                          -->
  <!--              - Added display of keys when they are part of SuppQuals.                                     -->
  <!--              - Changed column label "Controlled Terms or Format" to "Controlled Terms or ISO Format"      -->
  <!--              - Changed Methods label to "Derivations" and ValueLists to "Value Level Metadata"            -->
  <!--   2017-03-28 - Removed Key column from variable metadata table.                                           -->
  <!--   2017-03-19 - SDTM/SEND/ADaM variable metadata tables now have the same columns and headers.             -->
  <!--   2017-03-15 - Added Added link to MethodDef/FormalExpression from dataset/VLM table.                     -->
  <!--              - Honoring leading blanks in methods.                                                        -->
  <!--              - Honoring leading blanks in CodeListItem Decodes in the CodeLists table.                    -->
  <!--              - Removed check for valid ItemGroupDef/@Purpose values.                                      -->
  <!--   2017-02-16 - Added External CodeList comments display.                                                  -->
  <!--              - The TableItemDefSDS template now displays DisplayFormat instead of Length when available.  -->
  <!--   2017-01-10 - Fixed duplicate CRF title display.                                                         -->
  <!--   2016-12-07 - Fixed display of Origin Description when there is more than one.                           -->
  <!--   2016-11-15 - Switched Location and Documentation in dataset display.                                    -->
  <!--   2016-10-31 - Changed Standard/StandardVersion display to StudyName.                                     -->
  <!--   2016-08-25 - Removed duplicate Standard/StandardVersion display in Define-XML 2.1.                      -->
  <!--              - Making dataset names clickable instead of labels for consistency.                          -->
  <!--              - Variable name no longer links to VLM, but a separate superscript "VLM" link.               -->
  <!--              - In Analysis Results Details table, add link to dataset an analysis variable is coming from.-->
  <!--   2016-08-08 - Added external documents icon.                                                             -->
  <!--   2016-08-01 - Fixed external documents display in a new window for documents in TOC.                     -->
  <!--   2016-07-14 - Added Supplemental Documents container.                                                    -->
  <!--              - Open external documents (pdf) in a new window.                                             -->
  <!--   2016-07-05 - Added Page display to linkSinglePageHyperlink template.                                    -->
  <!--   2016-06-21 - Improved ARM arm:Code display by wrapping really long lines.                               -->
  <!--   2016-06-09 - Added displayPrefix and displayLengthDFormatSD parameters.                                 -->
  <!--              - Honoring linebreaks in methods (also changed to indent="no").                              -->
  <!--              - Changed Standard/@Package to Standard/@PublishingSet (Draft Define-XML 2.1).               -->               
  <!--   2016-03-10 - Updated ItemDef display of: Length [Significant Digits] : Display Format.                  -->
  <!--   2016-03-09 - Added Comment and DocumentRef display (Drfat Define-XML 2.1) for MetaDataVersion and       -->
  <!--                CodeList.                                                                                  -->
  <!--              - Added display of:                                                                          -->
  <!--                  ItemGroupDef/def:StandardOID, ItemGroupDef/def:IsNonStandard, CodeList/def:StandardOID   -->
  <!--              - Added display of def:Origin/@Source (Draft Define-XML 2.1).                                -->
  <!--              - Added Standard table (Draft Define-XML 2.1).                                               -->
  <!--              - Added def:PDFPageRef/@Title                                                                -->
  <!--              - Changed the Method display to honor linebreaks.                                            -->
  <!--   2016-03-02 - Added prefixes in 'Derivation / Comment' and 'Source / Derivation / Comment' columns.      -->
  <!--              - Added display of MethodDef/FormalExpression.                                               -->
  <!--              - Added display of CodeList/Description.                                                     -->
  <!--              - Added display of def:Origin/Description and def:DocumentRef.                               -->
  <!--              - Added display of ValueList/Description (Draft Define-XML 2.1).                             -->
  <!--              - Added display of ExternalCodeList/ExternalCodeList/@ref.                                   -->
  <!--   2016-02-11 - Improved Controlled Terms or Format display for CodeList Items and Enumerated Items.       -->
  <!--                The number of CodeList Items to display in the "Controlled Terms or Format" column is now  -->
  <!--                driven by the parameter nCodeListItemDisplay (default=5).                                  -->
  <!--                For external dictionaries the dictionary and version are displayed in the "Controlled      -->
  <!--                Terms or Format" column below the link.                                                    -->
  <!--   2016-02-08 - CRF Origin display no longer hardcoded as "CRF Page", but uses the real title.             -->
  <!--              - Display of "ISO 8601" in the "Controlled Terms or Format" column is now completely driven  -->
  <!--                by the DataType.                                                                           -->
  <!--   2016-02-04 - Fixed issue with PDF pages that are invalid, for example 12A.                              -->
  <!--   2015-02-13 - Fixed issue where multiple documents would result in displaying the first document         -->
  <!--                multiple times in the Dataset and Value Level Metadata sections.                           -->
  <!--              - For displaying the annotated CRF documents:                                                -->
  <!--                When there is no def:AnnotatedCRF element, loop over the def:leaf elements and see if      -->
  <!--                these are referenced from any ItemDef/def:Origin/def:DocumentRef elements.                 -->
  <!--              - Added support for multiple def:Origin elements and multiple documents within a def:Origin. -->
  <!--              - Links to Annotated CRFs in def:Origin is no longer taken from the def:AnnotatedCRF element -->
  <!--   2015-01-16 - Added Study metadata display                                                               -->                                 
  <!--              - Improved Analysis Parameter(s) display                                                     -->
  <!--   2014-08-29 - Added displayMethodsTable parameter.                                                       -->
  <!--              - Added link when href has a value in ExternalCodeList (AppendixExternalCodeLists template). -->
  <!--              - Many improvements for linking to external PDF documents with physical page references or   -->
  <!--                named destinations.                                                                        -->
  <!--   2013-12-12 - Fixed with non-existing CodeList being linked.                                             -->
  <!--   2013-08-10 - Fixed issue in value level where clause display.                                           -->
  <!--              - Removed Comment sorting.                                                                   -->
  <!--              - Added Analysis Results Metadata.                                                           -->
  <!--   2013-04-24 - Fixed issue in displayISO8601 template when ItemDef/@Name has length=1.                    -->
  <!--   2013-03-04 - Initial version.                                                                           -->
  <!--                                                                                                           -->  
  <!-- ********************************************************************************************************* -->
  
  <!-- Global Variables (constants) -->

  <xsl:variable name="STYLESHEET_VERSION" select="'2018-11-21'"/>
  
  <!-- XSLT 1.0 does not support the function 'upper-case()', so we need to use the 'translate() function, 
    which uses the variables $lowercase and $uppercase. -->
  <xsl:variable name="LOWERCASE" select="'abcdefghijklmnopqrstuvwxyz'"/>
  <xsl:variable name="UPPERCASE" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>  
  
  <xsl:variable name="REFTYPE_PHYSICALPAGE">PhysicalRef</xsl:variable>
  <xsl:variable name="REFTYPE_NAMEDDESTINATION">NamedDestination</xsl:variable>
  
  <xsl:variable name="Comparator_EQ"><text> = </text></xsl:variable>
  <xsl:variable name="Comparator_NE"><text> &#x2260; </text></xsl:variable>
  <xsl:variable name="Comparator_LT"><text> &lt; </text></xsl:variable>
  <xsl:variable name="Comparator_LE"><text> &#x2264; </text></xsl:variable>
  <xsl:variable name="Comparator_GT"><text> &gt; </text></xsl:variable>
  <xsl:variable name="Comparator_GE"><text> &#x2265; </text></xsl:variable>
  
  <xsl:variable name="PREFIX_COMMENT_TEXT"><span class="prefix"><xsl:text>[Comment] </xsl:text> </span></xsl:variable>
  <xsl:variable name="PREFIX_METHOD_TEXT"><span class="prefix"><xsl:text>[Method]</xsl:text></span></xsl:variable>
  <xsl:variable name="PREFIX_ORIGIN_TEXT"><span class="prefix"><xsl:text>[Origin] </xsl:text></span></xsl:variable>
  
  <!-- Global Variables (XPath) -->

  <xsl:variable name="g_StudyName" select="/odm:ODM/odm:Study[1]/odm:GlobalVariables[1]/odm:StudyName"/>
  <xsl:variable name="g_StudyDescription" select="/odm:ODM/odm:Study[1]/odm:GlobalVariables[1]/odm:StudyDescription"/>
  <xsl:variable name="g_ProtocolName" select="/odm:ODM/odm:Study[1]/odm:GlobalVariables[1]/odm:ProtocolName"/>
  
  <xsl:variable name="g_MetaDataVersion" select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]"/>
  <xsl:variable name="g_MetaDataVersionName" select="$g_MetaDataVersion/@Name"/>
  <xsl:variable name="g_MetaDataVersionDescription" select="$g_MetaDataVersion/@Description"/>
  <xsl:variable name="g_DefineVersion" select="$g_MetaDataVersion/@def:DefineVersion"/>
  
  <xsl:variable name="g_seqStandard" select="$g_MetaDataVersion/def:Standards/def:Standard"/>
  <xsl:variable name="g_seqItemGroupDefs" select="$g_MetaDataVersion/odm:ItemGroupDef"/>
  <xsl:variable name="g_seqItemDefs" select="$g_MetaDataVersion/odm:ItemDef"/>
  <xsl:variable name="g_seqItemDefsValueListRef" select="$g_MetaDataVersion/odm:ItemDef/def:ValueListRef"/>
  <xsl:variable name="g_seqCodeLists" select="$g_MetaDataVersion/odm:CodeList"/>
  <xsl:variable name="g_seqValueListDefs" select="$g_MetaDataVersion/def:ValueListDef"/>
  <xsl:variable name="g_seqMethodDefs" select="$g_MetaDataVersion/odm:MethodDef"/>
  <xsl:variable name="g_seqCommentDefs" select="$g_MetaDataVersion/def:CommentDef"/>
  <xsl:variable name="g_seqWhereClauseDefs" select="$g_MetaDataVersion/def:WhereClauseDef"/>
  <xsl:variable name="g_seqleafs" select="$g_MetaDataVersion/def:leaf"/>
  
  <xsl:variable name="g_StandardName">
    <xsl:choose>
      <xsl:when test="$g_MetaDataVersion/@def:StandardName">
        <!-- Define-XML v2.0 -->
        <xsl:value-of select="$g_MetaDataVersion/@def:StandardName" />
      </xsl:when>
      <xsl:otherwise >
        <!-- Define-XML v2.1 -->
        <xsl:value-of select="$g_MetaDataVersion/def:Standards/def:Standard[@Type='IG' and @IsDefault='Yes']/@Name"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="g_StandardVersion">
    <xsl:choose>
      <xsl:when test="$g_MetaDataVersion/@def:StandardVersion">
        <!-- Define-XML v2.0 -->
        <xsl:value-of select="$g_MetaDataVersion/@def:StandardVersion" />
      </xsl:when>
      <xsl:otherwise >
        <!-- Define-XML v2.1 -->
        <xsl:value-of select="$g_MetaDataVersion/def:Standards/def:Standard[@Type='IG' and @IsDefault='Yes']/@Version"/>        
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <!-- ***************************************************************** -->
  <!-- Create the HTML Header                                            -->
  <!-- ***************************************************************** -->
  <xsl:template match="/">
    <html lang="en">
      <xsl:call-template name="displaySystemProperties"/>
      <head>
        <xsl:text>&#xA;  </xsl:text>
        <meta http-equiv="Content-Script-Type" content="text/javascript"/>
        <xsl:text>&#xA;  </xsl:text>
        <meta http-equiv="Content-Style-Type" content="text/css"/>
        <xsl:text>&#xA;  </xsl:text>
        <title><xsl:value-of select="$g_StudyName"/>, <xsl:value-of select="$g_StandardName"/> <xsl:value-of select="$g_StandardVersion"/></title>
        <xsl:text>&#xA;</xsl:text>
        <xsl:call-template name="generateJavaScript"/>
        <xsl:text>&#xA;  </xsl:text>
        <xsl:call-template name="generateCSS"/>
        <xsl:text>&#xA;  </xsl:text>
      </head>
      <body onload="reset_menus();">

        <xsl:call-template name="generateMenu"/>
        <xsl:call-template name="generateMain"/>

      </body>
    </html>
  </xsl:template>
  
  <!-- **************************************************** -->
  <!-- **************  Create the Bookmarks  ************** -->
  <!-- **************************************************** -->
    <xsl:template name="generateMenu">
    <div id="menu">
      <!--  Skip Navigation Link for Accessibility -->
      <a name="top" class="invisible" href="#main">Skip Navigation Link</a>

      <span class="study-name">
        <xsl:value-of select="$g_StudyName"/>
      </span>

      
      <ul class="hmenu">
        
        <!-- **************************************************** -->
        <!-- **************  Annotated CRF    ******************* -->
        <!-- **************************************************** -->
        <xsl:choose>
          <xsl:when test="$g_MetaDataVersion/def:AnnotatedCRF">
            <xsl:for-each select="$g_MetaDataVersion/def:AnnotatedCRF/def:DocumentRef">
              <li class="hmenu-item">
                <span class="hmenu-bullet">+</span>
                <xsl:variable name="leafID" select="@leafID"/>
                <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafID]"/>
                <xsl:choose>
                  <xsl:when test="../../def:leaf[@ID=$leafID]">
                    <a class="external tocItem">
                      <xsl:attribute name="href"><xsl:value-of select="$leaf/@xlink:href"/></xsl:attribute>
                      <xsl:value-of select="$leaf/def:title"/>
                    </a>
                  </xsl:when>
                  <xsl:otherwise>
                    <span class="tocItem unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$leafID"/><xsl:text>]</xsl:text></span>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="displayImage" />
              </li>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <!-- No def:AnnotatedCRF element, then loop over the def:leaf elements and  
                 see if these are referenced from ItemDef/def:Origin/def:DocumentRef elements -->           
            <xsl:for-each select="$g_MetaDataVersion/def:leaf">
              <xsl:variable name="leafID" select="@ID"/>
              <!-- Define-XML v2.0: @Type='CRF', Define-XML v2.1: @Type='Collected' -->
              <xsl:if test="$g_seqItemDefs/def:Origin[@Type='CRF' or @Type='Collected']/def:DocumentRef[@leafID=$leafID]">
                <li class="hmenu-item">
                  <span class="hmenu-bullet">+</span>
                  <a class="external tocItem">
                    <xsl:attribute name="href"><xsl:value-of select="@xlink:href"/></xsl:attribute>
                    <xsl:value-of select="def:title"/>
                  </a>
                  <xsl:call-template name="displayImage" />
                </li>
              </xsl:if> 
            </xsl:for-each>
          </xsl:otherwise>  
        </xsl:choose>

        <!-- **************************************************** -->
        <!-- **************  Supplemental Doc ******************* -->
        <!-- **************************************************** -->
        <xsl:if test="$g_MetaDataVersion/def:SupplementalDoc">

          <li class="hmenu-submenu">
            <span onclick="toggle_submenu(this);" class="hmenu-bullet">+</span>
            <a class="tocItem">Supplemental Documents</a>
            <ul>
              
              <xsl:for-each select="$g_MetaDataVersion/def:SupplementalDoc/def:DocumentRef">
                <xsl:variable name="leafIDs" select="@leafID"/>
                <xsl:variable name="leaf" select="../../def:leaf[@ID=$leafIDs]"/>
                <xsl:variable name="leafID" select="$leaf/@ID"/>                  
                <xsl:choose>
                  <!-- Only display when the document is not part of the def:AnnotatedCRF container 
                       or linked from an ItemDef/def:Origin/def:DocumentRef -->
                  <xsl:when test="$g_MetaDataVersion/def:AnnotatedCRF/def:DocumentRef[@leafID=$leafID]"/>
                  <xsl:otherwise>
                    <li class="hmenu-item">
                      <xsl:choose>
                        <xsl:when test="../../def:leaf[@ID=$leafIDs]">
                          <span class="hmenu-bullet">+</span>
                          <a class="external tocItem">
                            <xsl:attribute name="href"><xsl:value-of select="$leaf/@xlink:href"/></xsl:attribute>
                            <xsl:value-of select="$leaf/def:title"/>
                          </a>
                        </xsl:when>
                        <xsl:otherwise>
                          <span class="hmenu-bullet">+</span>
                          <span class="tocItem unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$leafIDs"/><xsl:text>]</xsl:text></span>
                        </xsl:otherwise>
                      </xsl:choose>
                      <xsl:call-template name="displayImage" />
                    </li>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
              
            </ul>
          </li>
        </xsl:if>
            
        <!-- **************************************************** -->
        <!-- ************ Standards ***************************** -->
        <!-- **************************************************** -->
        <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:Standards">
          <li class="hmenu-item" >
            <span class="hmenu-bullet" onclick="toggle_submenu(this);">-</span>
            <a class="tocItem" href="#Standards_Table">Standards</a>
          </li>
        </xsl:if>
        
        <!-- **************************************************** -->
      	<!-- ************ Analysis Results Metadata ************* -->
      	<!-- **************************************************** -->
      	<xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/arm:AnalysisResultDisplays">
      		<li class="hmenu-submenu" >
      			<span class="hmenu-bullet" onclick="toggle_submenu(this);">+</span>
      			<a class="tocItem" href="#ARM_Table_Summary" >Analysis Results Metadata</a>
      			<ul> 
      				<xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/arm:AnalysisResultDisplays/arm:ResultDisplay">
      					<li class="hmenu-item">
      						<span class="hmenu-bullet">-</span>
      						<a class="tocItem">
      						  <xsl:attribute name="href">#ARD.<xsl:value-of select="@OID"/></xsl:attribute>
      						  <xsl:attribute name="title"><xsl:value-of select="./odm:Description/odm:TranslatedText"/></xsl:attribute>
      						  <xsl:value-of select="@Name"/>
      						</a>
      					</li>
      				</xsl:for-each>
      			</ul>
      		</li>
      	</xsl:if>
      	
      	<!-- **************************************************** -->
        <!-- ************** Datasets **************************** -->
        <!-- **************************************************** -->
        <li class="hmenu-submenu">
          <span class="hmenu-bullet" onclick="toggle_submenu(this);">+</span>
          <a class="tocItem" href="#datasets">Datasets</a>
          <ul>
            <xsl:for-each select="$g_seqItemGroupDefs">
              <li class="hmenu-item">
                <span class="hmenu-bullet">-</span>
                <a class="tocItem">
                  <xsl:attribute name="href">#IG.<xsl:value-of select="@OID"/></xsl:attribute>
                  <xsl:value-of select="concat(@Name, ' (',./odm:Description/odm:TranslatedText, ')')"/>
                </a>
              </li>
            </xsl:for-each>
          </ul>
        </li>

        <!-- **************************************************** -->
        <!-- ******************** Code Lists ******************** -->
        <!-- **************************************************** -->
        <xsl:if test="$g_seqCodeLists">
          <li class="hmenu-submenu">
            <span onclick="toggle_submenu(this);" class="hmenu-bullet">+</span>
            <a href="#decodelist" class="tocItem">Controlled Terminology</a>
            <ul>
              <xsl:if test="$g_seqCodeLists[odm:CodeListItem|odm:EnumeratedItem]">
                <li class="hmenu-submenu">
                  <span class="hmenu-bullet" onclick="toggle_submenu(this);">+</span>
                  <a class="tocItem" href="#decodelist">CodeLists</a>
                  <ul>
                    <xsl:for-each select="$g_seqCodeLists[odm:CodeListItem|odm:EnumeratedItem]">
                      <li class="hmenu-item">
                        <span class="hmenu-bullet">-</span>
                        <a class="tocItem">
                          <xsl:attribute name="href">#CL.<xsl:value-of select="@OID"/></xsl:attribute>
                          <xsl:value-of select="@Name"/>
                        </a>
                      </li>
                    </xsl:for-each>
                  </ul>
                </li>
              </xsl:if>

              <!-- **************************************************** -->
              <!-- ************** External Dictionaries *************** -->
              <!-- **************************************************** -->
              <xsl:if test="$g_seqCodeLists[odm:ExternalCodeList]">
                <li class="hmenu-submenu">
                  <span class="hmenu-bullet" onclick="toggle_submenu(this);">+</span>
                  <a class="tocItem" href="#externaldictionary">External Dictionaries</a>
                  <ul>
                    <xsl:for-each select="$g_seqCodeLists[odm:ExternalCodeList]">
                      <li class="hmenu-item">
                        <span class="hmenu-bullet">-</span>
                        <a class="tocItem">
                          <xsl:attribute name="href">#CL.<xsl:value-of select="@OID"/></xsl:attribute>
                          <xsl:value-of select="@Name"/>
                        </a>
                      </li>
                    </xsl:for-each>
                  </ul>
                </li>
              </xsl:if>

            </ul>
          </li>

        </xsl:if>

        <!-- **************************************************** -->
        <!-- ****************** Methods ************************* -->
        <!-- **************************************************** -->
        <xsl:if test="$displayMethodsTable = '1'">
          <xsl:if test="$g_seqMethodDefs">
            <li class="hmenu-submenu">
              <span class="hmenu-bullet" onclick="toggle_submenu(this);">+</span>
              <a class="tocItem" href="#compmethod">Methods</a>
              <ul>
                <xsl:for-each select="$g_seqMethodDefs">
                  <li class="hmenu-item">
                    <span class="hmenu-bullet">-</span>
                    <a class="tocItem">
                      <xsl:attribute name="href">#MT.<xsl:value-of select="@OID"/></xsl:attribute>
                      <xsl:value-of select="@Name"/>
                    </a>
                  </li>
                </xsl:for-each>
              </ul>
            </li>
          </xsl:if>
        </xsl:if>

        <!-- **************************************************** -->
        <!-- ****************** Comments ************************ -->
        <!-- **************************************************** -->
        <xsl:if test="$displayCommentsTable = '1'">
          <xsl:if test="$g_seqCommentDefs">
            <li class="hmenu-submenu">
              <span class="hmenu-bullet" onclick="toggle_submenu(this);">+</span>
              <a class="tocItem" href="#comment">Comments</a>
              <ul>
                <xsl:for-each select="$g_seqCommentDefs">
                  <li class="hmenu-item">
                    <span class="hmenu-bullet">-</span>
                    <a class="tocItem">
                      <xsl:attribute name="href">#COMM.<xsl:value-of select="@OID"/></xsl:attribute>
                      <xsl:value-of select="@OID"/>
                    </a>
                  </li>
                </xsl:for-each>
              </ul>
            </li>
          </xsl:if>
        </xsl:if>
      </ul>
 
      <!-- **************************************************** -->
      <!-- ****************** VLM toggles ********************* -->
      <!-- **************************************************** -->
      <xsl:call-template name="displayButtons" />
      
      
    </div>
    <!-- end of menu -->
    </xsl:template>

    
  <!-- **************************************************** -->
  <!-- **************  Create the Main Content ************ -->
  <!-- **************************************************** -->
  <xsl:template name="generateMain">
    
    <!-- start of main -->
    <div id="main">

      <!-- Display Document Info -->
      <div class="docinfo">
        <xsl:call-template name="displayODMCreationDateTimeDate"/>
        <xsl:call-template name="displayDefineXMLVersion"/>
        <xsl:call-template name="displayContext"/>
        <xsl:call-template name="displayStylesheetDate"/>
      </div>
      
      <!-- Display Study metadata -->
      <xsl:call-template name="tableStudyMetadata">
        <xsl:with-param name="g_StandardName" select="$g_StandardName"/>
        <xsl:with-param name="g_StandardVersion" select="$g_StandardVersion"/>
        <xsl:with-param name="g_StudyName" select="$g_StudyName"/>
        <xsl:with-param name="g_StudyDescription" select="$g_StudyDescription"/>
        <xsl:with-param name="g_ProtocolName" select="$g_ProtocolName"/>
        <xsl:with-param name="g_MetaDataVersionName" select="$g_MetaDataVersionName"/>
        <xsl:with-param name="g_MetaDataVersionDescription" select="$g_MetaDataVersionDescription"/>
      </xsl:call-template>
 
      <!-- ***************************************************************** -->
      <!-- Create the Standards Table                                        -->
      <!-- ***************************************************************** -->
      <xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/def:Standards">
        <xsl:call-template name="tableStandards"/>    
      </xsl:if>  
      
      <!-- ***************************************************************** -->
    	<!-- Create the ADaM Results Metadata Tables                           -->
    	<!-- ***************************************************************** -->
    	
    	<xsl:if test="/odm:ODM/odm:Study/odm:MetaDataVersion/arm:AnalysisResultDisplays">
    		<xsl:call-template name="tableAnalysisResultsSummary"/>
    		<xsl:call-template name="tableAnalysisResultsDetails"/>
    	</xsl:if>

      <!-- ***************************************************************** -->
      <!-- Create the Data Definition Tables                                 -->
      <!-- ***************************************************************** -->
      <xsl:call-template name="tableItemGroups"/>    
      
      <!-- ***************************************************************** -->
      <!-- Detail for the Data Definition Tables                             -->
      <!-- ***************************************************************** -->

      <xsl:for-each select="$g_seqItemGroupDefs">
         <xsl:call-template name="tableItemDefs"/>
      </xsl:for-each>

      <!-- ****************************************************  -->
      <!-- Create the Value Level Metadata (Value List)          -->
      <!-- ****************************************************  -->
      <!-- 
      <xsl:call-template name="tableValueLists"/>
       -->
      
      <!-- ***************************************************************** -->
      <!-- Create the Code Lists, Enumerated Items and External Dictionaries -->
      <!-- ***************************************************************** -->
      <xsl:call-template name="tableCodeLists"/>
      <xsl:call-template name="tableExternalCodeLists"/>

      <!-- ***************************************************************** -->
      <!-- Create the Methods                                                -->
      <!-- ***************************************************************** -->
      <xsl:if test="$displayMethodsTable = '1'">
        <xsl:call-template name="tableMethods"/>
      </xsl:if>

      <!-- ***************************************************************** -->
      <!-- Create the Comments                                               -->
      <!-- ***************************************************************** -->
      <xsl:if test="$displayCommentsTable = '1'">
        <xsl:call-template name="tableComments"/>
      </xsl:if>

    </div>
    <!-- end of main -->
    
  </xsl:template>

  <!-- **************************************************** -->
  <!-- Display Study Metadata                               -->
  <!-- **************************************************** -->
  <xsl:template name="tableStudyMetadata">
    <xsl:param name="g_StandardName"/>
    <xsl:param name="g_StandardVersion"/>
    <xsl:param name="g_StudyName"/>
    <xsl:param name="g_StudyDescription"/>
    <xsl:param name="g_ProtocolName"/>
    <xsl:param name="g_MetaDataVersionName"/>
    <xsl:param name="g_MetaDataVersionDescription"/>
    
    <div class="study-metadata">
      <dl class="study-metadata">
        <xsl:if test="$g_MetaDataVersion/@def:StandardName">
          <dt>Standard</dt>
          <dd>
            <xsl:value-of select="$g_StandardName"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$g_StandardVersion" />
          </dd>
        </xsl:if>
        <dt>Study Name</dt>
        <dd>
          <xsl:value-of select="$g_StudyName"/>
        </dd>
        <dt>Study Description</dt>
        <dd>
          <xsl:value-of select="$g_StudyDescription"/>
        </dd>
        <dt>Protocol Name</dt>
        <dd>
          <xsl:value-of select="$g_ProtocolName"/>
        </dd>
        <dt>Metadata Name</dt>
        <dd>
          <xsl:value-of select="$g_MetaDataVersionName"/>
        </dd>
        <xsl:if test="$g_MetaDataVersionDescription">
          <dt>Metadata Description</dt>
          <dd>
            <xsl:value-of select="$g_MetaDataVersionDescription"/>            
          </dd>
        </xsl:if>
      </dl>
      
      <!--  Define-XML v2.1 -->
      <xsl:if test="$g_MetaDataVersion/@def:CommentOID">
        <div class="description">
          <xsl:call-template name="displayComment">
            <xsl:with-param name="CommentOID" select="$g_MetaDataVersion/@def:CommentOID" />
            <xsl:with-param name="CommentPrefix" select="$displayPrefix" />
            <xsl:with-param name="element" select="'p'" />
          </xsl:call-template>
        </div>
      </xsl:if>
      
    </div>
  </xsl:template>

  <!-- **************************************************** -->
  <!-- Display Standards Metadata (Define-XML v2.1)         -->
  <!-- **************************************************** -->
  <xsl:template name="tableStandards">
    
    <h1 class="invisible">Standards for Study <xsl:value-of
      select="/odm:ODM/odm:Study/odm:GlobalVariables/odm:StudyName"/></h1>
 
    <div class="containerbox">
      
      <table id="Standards_Table" summary="Standards">
        <caption class="header">Standards for Study <xsl:value-of
          select="/odm:ODM/odm:Study/odm:GlobalVariables/odm:StudyName"/></caption>
        <tr class="header">
          <th scope="col">Standard</th>
          <th scope="col">Type</th>
          <th scope="col">Status</th>
          <th scope="col">Documentation</th>
        </tr>
        <xsl:for-each select="$g_seqStandard">
          <xsl:call-template name="tableRowStandards"/>
        </xsl:for-each>
      </table>
    </div>
    <xsl:call-template name="lineBreak"/>
    
  </xsl:template>
  
  <!-- **************************************************** -->
  <!-- Template: TableRowStandards (Define-XML v2.1)        -->
  <!-- **************************************************** -->
  <xsl:template name="tableRowStandards">
    
    <xsl:element name="tr">
      
      <xsl:call-template name="setRowClassOddeven">
        <xsl:with-param name="rowNum" select="position()"/>
      </xsl:call-template>
      
      <!-- Create an anchor -->
      <xsl:attribute name="id">STD.<xsl:value-of select="@OID"/></xsl:attribute>
      
      <td>
        <xsl:value-of select="@Name"/>
        <xsl:text> </xsl:text>
        
        <xsl:if test="@PublishingSet">
          <xsl:value-of select="@PublishingSet"/>
          <xsl:text> </xsl:text>
        </xsl:if>
        
        <xsl:value-of select="@Version"/>
      </td>
      <td><xsl:value-of select="@Type"/></td>
      <td><xsl:value-of select="@Status"/></td>
      
      <!-- ************************************************ -->
      <!-- Comments                                         -->
      <!-- ************************************************ -->
      <td>
        <xsl:call-template name="displayComment">
          <xsl:with-param name="CommentOID" select="@def:CommentOID" />
          <xsl:with-param name="CommentPrefix" select="$displayPrefix" />
        </xsl:call-template>
      </td>
      
    </xsl:element>
  </xsl:template>
  
  <!-- **************************************************** -->
  <!-- Analysis Results Summary                             -->
  <!-- **************************************************** -->
  <xsl:template name="tableAnalysisResultsSummary">
    <div class="containerbox">
      <h1 id="ARM_Table_Summary">Analysis Results Metadata - Summary</h1>
      <div class="arm-summary">
        <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/arm:AnalysisResultDisplays/arm:ResultDisplay">
          <xsl:variable name="DisplayOID" select="@OID"/>
          <xsl:variable name="DisplayName" select="@Name"/>
          <xsl:variable name="Display" select="/odm:ODM/odm:Study/odm:MetaDataVersion/arm:AnalysisResultDisplays/arm:ResultDisplay[@OID=$DisplayOID]"/>
          <div class="arm-summary-resultdisplay">
            <a>
              <xsl:attribute name="href">#ARD.<xsl:value-of select="$DisplayOID"/></xsl:attribute>
              <xsl:value-of select="$DisplayName"/>
            </a>
            <span class="arm-display-title">
              <xsl:value-of select="./odm:Description/odm:TranslatedText"/>
            </span>
          <!-- list each analysis result linked to the respective rows in the detail tables-->
          <xsl:for-each select="./arm:AnalysisResult">
            <xsl:variable name="AnalysisResultID" select="./@OID"/>
            <xsl:variable name="AnalysisResult" select="$Display/arm:AnalysisResults[@OID=$AnalysisResultID]"/>
            <p class="arm-summary-result">
              <a>
                <xsl:attribute name="href">#AR.<xsl:value-of select="$AnalysisResultID"/></xsl:attribute>
                <xsl:value-of select="./odm:Description/odm:TranslatedText"/>
              </a>
            </p>
          </xsl:for-each>
          </div>
        </xsl:for-each>
      </div>
    </div> 
    
    <xsl:call-template name="lineBreak"/>
    
  </xsl:template>
  
  <!-- **************************************************** -->
  <!--  Analysis Results Details                            -->
  <!-- **************************************************** -->
  <xsl:template name="tableAnalysisResultsDetails">
      <h1>Analysis Results Metadata - Detail</h1>

      <xsl:for-each select="/odm:ODM/odm:Study/odm:MetaDataVersion/arm:AnalysisResultDisplays/arm:ResultDisplay">

        <div class="containerbox">
          <xsl:variable name="DisplayOID" select="@OID"/>
          <xsl:variable name="DisplayName" select="@Name"/>
          <xsl:variable name="Display" select="/odm:ODM/odm:Study/odm:MetaDataVersion/arm:AnalysisResultDisplays/arm:ResultDisplay[@OID=$DisplayOID]"/>
  
          <a>
            <xsl:attribute name="id">ARD.<xsl:value-of select="$DisplayOID"/></xsl:attribute>
          </a>
  
          <xsl:element name="table">
            
            <xsl:attribute name="class">analysisresults-detail</xsl:attribute>
            <xsl:attribute name="summary">Analysis Results Metadata - Detail</xsl:attribute>
            <caption>
              <xsl:value-of select="$DisplayName"/>
            </caption>
  
            <tr>
              <th scope="col" class="arm-resultlabel">Display</th>
              <th scope="col">
  
                <xsl:for-each select="def:DocumentRef">
                  <xsl:call-template name="displayDocumentRef">
                    <xsl:with-param name="element" select="'span'"/>
                  </xsl:call-template>
                </xsl:for-each>
                <xsl:text> </xsl:text>
                <span class="arm-displaytitle"><xsl:value-of select="$Display/odm:Description/odm:TranslatedText"/></span>
              </th>
            </tr>
  
            <!--
                  Analysis Results
                -->
  
            <xsl:for-each select="$Display/arm:AnalysisResult">
              <xsl:variable name="AnalysisResultOID" select="@OID"/>
              <xsl:variable name="AnalysisResult" select="$Display/arm:AnalysisResult[@OID=$AnalysisResultOID]"/>
              <tr class="arm-analysisresult">
                <td>Analysis Result</td>
                <td>
                  <!--  add an identifier to Analysis Results xsl:value-of select="OID"/-->
                  <span class="arm-resulttitle">
                    <xsl:attribute name="id">AR.<xsl:value-of select="$AnalysisResultOID"/></xsl:attribute>
                    <xsl:value-of select="odm:Description/odm:TranslatedText"/>
                  </span>
                </td>
              </tr>
  
              <!--
                  Get the analysis parameter code from the where clause,
                  and then get the parameter from the decode in the codelist. 
                -->
  
              <xsl:variable name="ParameterOID" select="$AnalysisResult/@ParameterOID"/>
              <tr>
                
                <td class="arm-label">Analysis Parameter(s)</td>
                
                <td>
                  
                  <xsl:if test="$ParameterOID">
                    <xsl:if test="count($g_seqItemDefs[@OID=$ParameterOID]) = 0">
                      <span class="unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$ParameterOID"/><xsl:text>]</xsl:text></span>
                    </xsl:if>
                  </xsl:if>  

                  <xsl:for-each select="$AnalysisResult/arm:AnalysisDatasets/arm:AnalysisDataset">
  
                    <xsl:variable name="WhereClauseOID" select="def:WhereClauseRef/@WhereClauseOID"/>
                    <xsl:variable name="WhereClauseDef" select="$g_seqWhereClauseDefs[@OID=$WhereClauseOID]"/>
                    <xsl:variable name="ItemGroupOID" select="@ItemGroupOID"/>
                    
                    <!--  Get the RangeCheck associated with the parameter (typically only one ...) --> 
                    <xsl:for-each select="$WhereClauseDef/odm:RangeCheck[@def:ItemOID=$ParameterOID]">
                      
                      <xsl:variable name="whereRefItemOID" select="./@def:ItemOID"/>
                      <xsl:variable name="whereRefItemName" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@Name"/>
                      <xsl:variable name="whereRefItemDataType" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@DataType"/>
                      <xsl:variable name="whereOP" select="./@Comparator"/>
                      <xsl:variable name="whereRefItemCodeListOID"
                        select="$g_seqItemDefs[@OID=$whereRefItemOID]/odm:CodeListRef/@CodeListOID"/>
                      <xsl:variable name="whereRefItemCodeList"
                        select="$g_seqCodeLists[@OID=$whereRefItemCodeListOID]"/>
                      
                      <xsl:call-template name="ItemGroupItemLink">
                        <xsl:with-param name="ItemGroupOID" select="$ItemGroupOID"/>
                        <xsl:with-param name="ItemOID" select="$whereRefItemOID"/>
                        <xsl:with-param name="ItemName" select="$whereRefItemName"/>
                      </xsl:call-template> 
  
                      <xsl:choose>
                        <xsl:when test="$whereOP = 'IN' or $whereOP = 'NOTIN'">
                          <xsl:text> </xsl:text>
                          <xsl:variable name="Nvalues" select="count(./odm:CheckValue)"/>
                          <xsl:choose>
                            <xsl:when test="$whereOP='IN'">
                              <xsl:text> IN </xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:text> NOT IN </xsl:text>
                            </xsl:otherwise>
                          </xsl:choose>
                          <xsl:text> (</xsl:text>
                          <xsl:for-each select="./odm:CheckValue">
                            <xsl:variable name="CheckValueINNOTIN" select="."/>
                            <p class="linebreakcell"> 
                              <xsl:call-template name="displayValue">
                                <xsl:with-param name="Value" select="$CheckValueINNOTIN"/>
                                <xsl:with-param name="DataType" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@DataType"/>
                                <xsl:with-param name="decode" select="1"/>
                                <xsl:with-param name="CodeList" select="$whereRefItemCodeList"/>
                              </xsl:call-template>
                              <xsl:if test="position() != $Nvalues">
                                <xsl:value-of select="', '"/>
                              </xsl:if>
                            </p>
                          </xsl:for-each><xsl:text> ) </xsl:text>
                        </xsl:when>
  
                        <xsl:when test="$whereOP = 'EQ'">
                          <xsl:variable name="CheckValueEQ" select="./odm:CheckValue"/>
                          <xsl:text> = </xsl:text>
                          <xsl:call-template name="displayValue">
                            <xsl:with-param name="Value" select="$CheckValueEQ"/>
                            <xsl:with-param name="DataType" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@DataType"/>
                            <xsl:with-param name="decode" select="1"/>
                            <xsl:with-param name="CodeList" select="$whereRefItemCodeList"/>
                          </xsl:call-template>
                        </xsl:when>
  
                        <xsl:when test="$whereOP = 'NE'">
                          <xsl:variable name="CheckValueNE" select="./odm:CheckValue"/>
                          <xsl:text> &#x2260; </xsl:text>
                          <xsl:call-template name="displayValue">
                            <xsl:with-param name="Value" select="$CheckValueNE"/>
                            <xsl:with-param name="DataType" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@DataType"/>
                            <xsl:with-param name="decode" select="1"/>
                            <xsl:with-param name="CodeList" select="$whereRefItemCodeList"/>
                          </xsl:call-template>
                        </xsl:when>
  
                        <xsl:otherwise>
                          <xsl:variable name="CheckValueOTH" select="./odm:CheckValue"/>
                          <xsl:text> </xsl:text>
                          <xsl:choose>
                            <xsl:when test="$whereOP='LT'">
                              <xsl:text> &lt; </xsl:text>
                            </xsl:when>
                            <xsl:when test="$whereOP='LE'">
                              <xsl:text> &lt;= </xsl:text>
                            </xsl:when>
                            <xsl:when test="$whereOP='GT'">
                              <xsl:text> &gt; </xsl:text>
                            </xsl:when>
                            <xsl:when test="$whereOP='GE'">
                              <xsl:text> &gt;= </xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="$whereOP"/>
                            </xsl:otherwise>
                          </xsl:choose>
                          <xsl:call-template name="displayValue">
                            <xsl:with-param name="Value" select="$CheckValueOTH"/>
                            <xsl:with-param name="DataType" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@DataType"/>
                            <xsl:with-param name="decode" select="1"/>
                            <xsl:with-param name="CodeList" select="$whereRefItemCodeList"/>
                          </xsl:call-template>                        
                        </xsl:otherwise>
                      </xsl:choose>
                      
                      <br/>
                      <xsl:if test="position() != last()">
                        <xsl:text> and </xsl:text>
                      </xsl:if>
                      
                    </xsl:for-each>
                    
                    <!--  END - Get the RangeCheck associated with the parameter (typically only one ...) --> 
                  
                  </xsl:for-each>               
                  
                </td>
              </tr>
  
              <!--
                  The analysis Variables are next. It will link to ItemDef information.
                -->
              <tr>
                <td class="arm-label">Analysis Variable(s)</td>
                <td>
                  <xsl:for-each select="arm:AnalysisDatasets/arm:AnalysisDataset">
                    <xsl:variable name="ItemGroupOID" select="@ItemGroupOID"/>
                    <xsl:for-each select="arm:AnalysisVariable">
                      <xsl:variable name="ItemOID" select="@ItemOID"/>
                      <xsl:variable name="ItemDef" select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:ItemDef[@OID=$ItemOID]"/>
                        <p class="arm-analysisvariable">
                          <xsl:choose>
                            <xsl:when test="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:ItemGroupDef[@OID=$ItemGroupOID]">
                              <a>
                                <xsl:attribute name="href">#<xsl:value-of select="$ItemGroupOID"/></xsl:attribute>
                                <xsl:value-of select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:ItemGroupDef[@OID=$ItemGroupOID]/@Name"/>
                              </a>
                            </xsl:when>
                            <xsl:otherwise>
                              <span class="unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$ItemGroupOID"/><xsl:text>]</xsl:text></span>
                            </xsl:otherwise>
                          </xsl:choose>
                          <xsl:text>.</xsl:text>
                          
                          <xsl:choose>
                            <xsl:when test="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:ItemGroupDef[@OID=$ItemGroupOID] and /odm:ODM/odm:Study/odm:MetaDataVersion/odm:ItemDef[@OID=$ItemOID]">
                              <a>
                                <xsl:attribute name="href">#<xsl:value-of select="$ItemGroupOID"/>.<xsl:value-of select="$ItemOID"/></xsl:attribute>
                                <xsl:value-of select="$ItemDef/@Name"/>
                              </a> (<xsl:value-of select="$ItemDef/odm:Description/odm:TranslatedText"/>)
                              
                            </xsl:when>
                            <xsl:otherwise>
                              <span class="unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$ItemOID"/><xsl:text>]</xsl:text></span>
                            </xsl:otherwise>
                          </xsl:choose>
                        
                        </p>
                    </xsl:for-each>
                  </xsl:for-each>
                </td>
  
              </tr>
  
              <!-- Use the AnalysisReason attribute of the AnalysisResults -->
              <tr>
                <td class="arm-label">Analysis Reason</td>
                <td><xsl:value-of select="$AnalysisResult/@AnalysisReason"/></td>
              </tr>
              <!-- Use the AnalysisPurpose attribute of the AnalysisResults -->
              <tr>
                <td class="arm-label">Analysis Purpose</td>
                <td><xsl:value-of select="$AnalysisResult/@AnalysisPurpose"/></td>
              </tr>
              
              <!-- 
                  AnalysisDataset Data References
                -->
              <tr>
                <td class="arm-label">Data References (incl. Selection Criteria)</td>
                <td>
                  <xsl:for-each select="$AnalysisResult/arm:AnalysisDatasets/arm:AnalysisDataset">
                    <xsl:variable name="ItemGroupOID" select="@ItemGroupOID"/>
                    <xsl:variable name="ItemGroupDef" select="/odm:ODM/odm:Study/odm:MetaDataVersion/odm:ItemGroupDef[@OID=$ItemGroupOID]"/>
                    <div class="arm-data-reference">
                      <xsl:choose>
                        <xsl:when test="$ItemGroupDef/@OID">
                          <a>
                            <xsl:attribute name="href">#<xsl:value-of select="$ItemGroupDef/@OID"/></xsl:attribute>
                            <xsl:attribute name="title"><xsl:value-of select="$ItemGroupDef/odm:Description/odm:TranslatedText"/></xsl:attribute>
                            <xsl:value-of select="$ItemGroupDef/@Name"/>
                          </a>
                        </xsl:when>
                        <xsl:otherwise>
                          <span class="unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$ItemGroupOID"/><xsl:text>]</xsl:text></span>
                        </xsl:otherwise>
                      </xsl:choose>
                      
                      <xsl:text>  [</xsl:text>
                      <xsl:call-template name="displayWhereClause">
                        <xsl:with-param name="ValueItemRef"
                           select="$AnalysisResult/arm:AnalysisDatasets/arm:AnalysisDataset[@ItemGroupOID=$ItemGroupOID]"/>
                        <xsl:with-param name="ItemGroupLink" select="$ItemGroupOID"/>
                        <xsl:with-param name="decode" select="0"/>
                        <xsl:with-param name="break" select="0"/>
                      </xsl:call-template>
                      <xsl:text>]</xsl:text>
                    </div>
  
                  </xsl:for-each>
  
                  <!--AnalysisDatasets Comments-->
                  <xsl:for-each select="$AnalysisResult/arm:AnalysisDatasets">
                    <xsl:call-template name="displayComment">
                      <xsl:with-param name="CommentOID" select="@def:CommentOID" />
                      <xsl:with-param name="CommentPrefix" select="$displayPrefix" />
                    </xsl:call-template>
                  </xsl:for-each>                
  
               </td>
              </tr>
  
              <!--
                  if we have an arm:Documentation element
                  produce a row with the contained information
                -->
  
              <xsl:for-each select="$AnalysisResult/arm:Documentation">
                <tr>
                  <td class="arm-label">Documentation</td>
                  <td>
                    <span>
                      <xsl:value-of select="$AnalysisResult/arm:Documentation/odm:Description/odm:TranslatedText"/>
                    </span>
  
                    <xsl:for-each select="def:DocumentRef">
                      <xsl:call-template name="displayDocumentRef" />
                    </xsl:for-each>

                  </td>
                </tr>
              </xsl:for-each>
  
              <!--
                  if we have a arm:ProgrammingCode element
                  produce a row with the contained information
               -->
              <xsl:for-each select="$AnalysisResult/arm:ProgrammingCode">
                <tr>
                  <td class="arm-label">Programming Statements</td>
                  <td>
  
                    <xsl:if test="@Context">
                        <span class="arm-code-context">[<xsl:value-of select="@Context"/>]</span>
                    </xsl:if>  
  
                    <xsl:if test="arm:Code">
                      <pre class="arm-code"><xsl:value-of select="arm:Code"/></pre>
                    </xsl:if>  
  
                    <div class="arm-code-ref">
                      <xsl:for-each select="def:DocumentRef">
                        <xsl:call-template name="displayDocumentRef"/>
                      </xsl:for-each>
                    </div>

                  </td>
                </tr>
              </xsl:for-each>
  
            </xsl:for-each>
          </xsl:element>
        </div>
        
        <xsl:call-template name="linkTop"/>
        <xsl:call-template name="lineBreak"/>
        
      </xsl:for-each>
    
    <xsl:call-template name="lineBreak"/>
    
  </xsl:template>

  <!-- **************************************************** -->
  <!-- Template: TableItemGroups                            -->
  <!-- **************************************************** -->
  <xsl:template name="tableItemGroups">

    <a id="datasets"/>
    
    <h1 class="invisible">Datasets</h1>
    <div class="containerbox">
      
      <table summary="Data Definition Tables">
        <caption class="header">Datasets</caption>
        <tr class="header">
          <th scope="col">Dataset</th>
          <th scope="col">Description</th>
          <th scope="col">Class
            <!--  Define-XML v2.1 -->
            <xsl:if test="$g_seqItemGroupDefs/def:Class/def:SubClass/@Name"> - SubClass</xsl:if>
          </th>  
          <th scope="col">Structure</th>
          <th scope="col">Purpose</th>
          <th scope="col">Keys</th>
          <th scope="col">Documentation</th>
          <th scope="col">Location</th>
        </tr>
        
        <xsl:for-each select="$g_seqItemGroupDefs">
          <xsl:call-template name="tableRowItemGroupDefs" />
        </xsl:for-each>
      </table>
      
    </div>
    
    <xsl:call-template name="linkTop"/>
    <xsl:call-template name="lineBreak"/>
    
  </xsl:template>

  <!-- **************************************************** -->
  <!-- Template: TableRowItemGroupDefs                      -->
  <!-- **************************************************** -->
  <xsl:template name="tableRowItemGroupDefs">
    
    <xsl:element name="tr">

      <xsl:call-template name="setRowClassOddeven">
        <xsl:with-param name="rowNum" select="position()"/>
      </xsl:call-template>

      <!-- Create an anchor -->
      <xsl:attribute name="id"><xsl:value-of select="@OID"/></xsl:attribute>

      <td>
        <a>
          <xsl:attribute name="href">#IG.<xsl:value-of select="@OID"/></xsl:attribute>
          <xsl:value-of select="@Name"/>
        </a>
        
        <!--  Define-XML v2.1 -->
        <xsl:call-template name="displayStandard">
          <xsl:with-param name="element" select="'span'" />
        </xsl:call-template>  
        <!--  Define-XML v2.1 -->
        <xsl:call-template name="displayNonStandard">
          <xsl:with-param name="element" select="'span'" />
        </xsl:call-template>  
        <!--  Define-XML v2.1 -->
        <xsl:call-template name="displayNoData">
          <xsl:with-param name="element" select="'span'" />
        </xsl:call-template>  
        
      </td>

      <!-- *************************************************************** -->
      <!-- Link each ItemGroup to its corresponding section in the define  -->
      <!-- *************************************************************** -->
      <td>

        <xsl:value-of select="odm:Description/odm:TranslatedText"/>

        <xsl:variable name="ParentDescription">
          <xsl:call-template name="getParentDescription">
            <xsl:with-param name="OID" select="@OID" />
          </xsl:call-template>  
        </xsl:variable>
        <xsl:if test="string-length(normalize-space($ParentDescription)) &gt; 0">
          <xsl:text> (</xsl:text><xsl:value-of select="$ParentDescription"/><xsl:text>)</xsl:text>
        </xsl:if>

      </td>

      <!-- *************************************************************** -->

      <td>
        <xsl:call-template name="displayItemGroupClass"/>
      </td>
      
      <td>
        <xsl:value-of select="@def:Structure"/>
      </td>
      <td>
        <xsl:value-of select="@Purpose"/>
      </td>
      <td>
        <xsl:call-template name="displayItemGroupKeys"/>
      </td>

      <!-- ************************************************ -->
      <!-- Comments                                         -->
      <!-- ************************************************ -->
      <td>
        <xsl:call-template name="displayComment">
          <xsl:with-param name="CommentOID" select="@def:CommentOID" />
          <xsl:with-param name="CommentPrefix" select="$displayPrefix" />
        </xsl:call-template>
      </td>

      <!-- **************************************************** -->
      <!-- Link each Dataset to its corresponding archive file  -->
      <!-- **************************************************** -->
      
      <xsl:variable name="archiveLocationID" select="@def:ArchiveLocationID"/>
      <xsl:variable name="archiveTitle">
        <xsl:choose>
          <xsl:when test="def:leaf[@ID=$archiveLocationID]"><xsl:value-of select="def:leaf[@ID=$archiveLocationID]/def:title"/></xsl:when>
          <xsl:otherwise><xsl:text>[unresolved: </xsl:text><xsl:value-of select="@def:ArchiveLocationID"/><xsl:text>]</xsl:text></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <td>
        <xsl:if test="@def:ArchiveLocationID">
          <xsl:call-template name="displayHyperlink">
            <xsl:with-param name="href" select="def:leaf[@ID=$archiveLocationID]/@xlink:href"/>
            <xsl:with-param name="anchor" select="''"/>
            <xsl:with-param name="title" select="$archiveTitle"/>
          </xsl:call-template>
          </xsl:if>
      </td>
      
    </xsl:element>
  </xsl:template>

  <!-- ************************************************************ -->
  <!-- Template: tabelItemDefs                                      -->
  <!-- ************************************************************ -->
  <xsl:template name="tableItemDefs">

    <a id="IG.{@OID}"/>
    <div class="containerbox">

      <h1 class="invisible">
        <xsl:value-of select="concat(./odm:Description/odm:TranslatedText, ' (', @Name, ') ')"/>
      </h1>      

      <xsl:element name="table">
        <xsl:attribute name="summary">ItemGroup IG.<xsl:value-of select="@OID"/>
        </xsl:attribute>

        <caption>
          <span><xsl:call-template name="displayItemGroupDefHeader"/></span>
        </caption>

        <!-- *************************************************** -->
        <!-- Link to SUPPXX or SQAPXX domain                     -->
        <!-- For those domains with Suplemental Qualifiers       -->
        <!-- *************************************************** -->
        <xsl:call-template name="linkSuppQual"/>
        <xsl:call-template name="linkSQAP"/>
        
        <!-- *************************************************** -->
        <!-- Link to Parent domain                               -->
        <!-- For those domains that are Suplemental Qualifiers   -->
        <!-- *************************************************** -->
        <xsl:call-template name="linkParentDomain"/>
        <xsl:call-template name="linkApParentDomain"/>
        
        <xsl:variable name="nItemsWithVLM"><xsl:value-of select="count(./odm:ItemRef[@ItemOID=$g_seqItemDefsValueListRef/../@OID])"/></xsl:variable>
        
        <xsl:variable name="isSuppQual">
          <xsl:choose>
            <xsl:when test="starts-with(@Name, 'SUPP') or starts-with(@Name, 'SQAP')">1</xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>              
        </xsl:variable>
        
        <xsl:variable name="addRoleColumn">
          <xsl:choose>
            <xsl:when test="count(./odm:ItemRef/@Role) > 0 or $isSuppQual='1'">1</xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>              
        </xsl:variable>
 
        <xsl:variable name="addConditionColumn">
          <xsl:choose>
            <xsl:when test="$nItemsWithVLM > 0 and $isSuppQual='0'">1</xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>              
        </xsl:variable>
        
 
        <!-- Output the column headers -->
        <tr class="header">
          <th scope="col">Variable</th>
          <xsl:if test="$addConditionColumn='1'">
            <th scope="col">Where Condition</th>
          </xsl:if>  
          <th scope="col">Label / Description</th>
          <th scope="col">Type</th>
          <xsl:if test="$addRoleColumn='1'">
            <th scope="col">Role</th>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="$displayLengthDFormatSD='1'">
              <th scope="col" class="length">Length [SignificantDigits] : Display Format</th>
            </xsl:when>
            <xsl:otherwise>
              <th scope="col" class="length">Length or Display Format</th>
            </xsl:otherwise>
          </xsl:choose>
          <th scope="col" abbr="Format">Controlled Terms or ISO Format</th>
          <th scope="col">Origin / Source / Method / Comment</th>
        </tr>

        <!-- Get the individual data points -->
        <xsl:for-each select="./odm:ItemRef">

          <xsl:sort data-type="number" order="ascending" select="@OrderNumber"/>
          <xsl:variable name="ItemRef" select="."/>
          <xsl:variable name="ItemDefOID" select="@ItemOID"/>
          <xsl:variable name="ItemGroupDefOID" select="../@OID"/>
          <xsl:variable name="ItemDef" select="../../odm:ItemDef[@OID=$ItemDefOID]"/>

          <xsl:variable name="VLMClass">
            <xsl:choose>
              <xsl:when test="position() mod 2 = 0">
                <xsl:text>tableroweven</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>tablerowodd</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>            

          <xsl:element name="tr">

            <xsl:call-template name="setRowClassOddeven">
              <xsl:with-param name="rowNum" select="position()"/>
            </xsl:call-template>

            <td>
              <xsl:choose>
                <xsl:when test="$ItemDef/def:ValueListRef/@ValueListOID">
                  <xsl:value-of select="$ItemDef/@Name"/>
                  
                  <xsl:choose>
                    <xsl:when test="$g_seqValueListDefs[@OID = $ItemDef/def:ValueListRef/@ValueListOID]">
                      <xsl:element name="span">
                        <xsl:attribute name="class"><xsl:text>valuelist-reference</xsl:text></xsl:attribute>
                        <xsl:attribute name="onclick"><xsl:value-of select="concat('toggle_vlm(this)', ';')"/></xsl:attribute>
                        <a>
                          <xsl:attribute name="id">
                            <xsl:value-of select="../@OID"/>.<xsl:value-of select="$ItemDef/@OID"/>
                          </xsl:attribute>
                          <xsl:text>VLM</xsl:text>
                        </a>
                      </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:element name="span">
                        <xsl:attribute name="class"><xsl:text>valuelist-no-reference</xsl:text></xsl:attribute>
                        <span class="unresolved"><xsl:text>[unresolved: VLM]</xsl:text></span>
                      </xsl:element>
                      
                    </xsl:otherwise>
                  </xsl:choose>
                  
                </xsl:when>
                <xsl:otherwise>
                  <xsl:choose>
                  <xsl:when test="$ItemDef">
                  <!-- Make unique anchor link to Variable Name -->
                  <a>
                    <xsl:attribute name="id">
                      <xsl:value-of select="../@OID"/>.<xsl:value-of select="$ItemDef/@OID"/>
                    </xsl:attribute>
                  </a>
                  <xsl:value-of select="$ItemDef/@Name"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <span class="unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$ItemDefOID"/><xsl:text>]</xsl:text></span>
                  </xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>

              <!--  Define-XML v2.1 -->
              <xsl:call-template name="displayNonStandard">
                <xsl:with-param name="element" select="'span'" />
              </xsl:call-template>  

              <!--  Define-XML v2.1 -->
              <xsl:call-template name="displayNoData">
                <xsl:with-param name="element" select="'span'" />
              </xsl:call-template>  
              
            </td>

            <xsl:if test="$addConditionColumn='1'">
              <td></td>
            </xsl:if>  

            <td><xsl:value-of select="$ItemDef/odm:Description/odm:TranslatedText"/></td>
            <td class="datatype"><xsl:value-of select="$ItemDef/@DataType"/></td>

            <xsl:if test="$addRoleColumn='1'">
              <td class="role"><xsl:value-of select="@Role"/></td>
            </xsl:if>
            
            <xsl:choose>
              <xsl:when test="$displayLengthDFormatSD='1'">
                <td class="number">
                  <xsl:call-template name="displayItemDefLengthSignDigitsDisplayFormat">
                    <xsl:with-param name="ItemDef" select="$ItemDef"/>
                  </xsl:call-template>
                </td>
              </xsl:when>
              <xsl:otherwise>
                <td class="number">
                  <xsl:call-template name="displayItemDefLengthDFormat">
                    <xsl:with-param name="ItemDef" select="$ItemDef"/>
                  </xsl:call-template>
                </td>
              </xsl:otherwise>
            </xsl:choose>
            
            <!-- *************************************************** -->
            <!-- Hypertext Link to the Decode Appendix               -->
            <!-- *************************************************** -->
            <td>
              <xsl:call-template name="displayItemDefDecodeList">
                <xsl:with-param name="itemDef" select="$ItemDef"/>
              </xsl:call-template>

              <xsl:call-template name="displayItemDefISO8601">
                <xsl:with-param name="itemDef" select="$ItemDef"/>
              </xsl:call-template>
            </td>

            <!-- *************************************************** -->
            <!-- Origin / Source / Method / Comment              -->
            <!-- *************************************************** -->
            <td>

              <xsl:call-template name="displayItemDefOrigin">
                <xsl:with-param name="itemDef" select="$ItemDef"/>
                <xsl:with-param name="OriginPrefix" select="$displayPrefix"/>
              </xsl:call-template>

              <xsl:call-template name="displayItemDefMethod">
                <xsl:with-param name="MethodOID" select="$ItemRef/@MethodOID"/>
                <xsl:with-param name="MethodPrefix" select="$displayPrefix"/>
              </xsl:call-template>

              <xsl:call-template name="displayComment">
                <xsl:with-param name="CommentOID" select="$ItemDef/@def:CommentOID"/>
                <xsl:with-param name="CommentPrefix" select="$displayPrefix"/>
              </xsl:call-template>

            </td>
            
          </xsl:element> 

          <xsl:if test="$ItemDef/def:ValueListRef/@ValueListOID">
            <xsl:call-template name="tableValueListsInTable">
              <xsl:with-param name="OID"
                select="$ItemDef/def:ValueListRef/@ValueListOID"/>
              <xsl:with-param name="ParentItemDefOID"
                select="concat($ItemGroupDefOID, '.', $ItemDefOID)"/>
              <xsl:with-param name="addRoleColumn"
                select="$addRoleColumn"/>
              <xsl:with-param name="isSuppQual"
                select="$isSuppQual"/>
              <xsl:with-param name="VLMClass"
                select="$VLMClass"/>
            </xsl:call-template>
          </xsl:if>
          
        </xsl:for-each>
        
      </xsl:element>
    </div>
    
    <xsl:call-template name="linkTop"/>
    <xsl:call-template name="lineBreak"/>
    
  </xsl:template>

  <!-- ************************************************************************* -->
  <!-- Template: TableValueList InLine (handles the def:ValueListDef elements    -->
  <!-- ************************************************************************* -->
  <xsl:template name="tableValueListsInTable">
    
    <xsl:param name="OID"/>
    <xsl:param name="ParentItemDefOID"/>
    <xsl:param name="addRoleColumn"/>
    <xsl:param name="isSuppQual"/>
    <xsl:param name="VLMClass" />
    
        <xsl:for-each select="$g_seqValueListDefs[@OID=$OID]">

              <!-- Get the individual data points -->
              <xsl:for-each select="./odm:ItemRef">
                
                <xsl:sort data-type="number" order="ascending" select="@OrderNumber"/>

                <xsl:variable name="ItemRef" select="."/>
                <xsl:variable name="valueDefOID" select="@ItemOID"/>
                <xsl:variable name="valueDef" select="../../odm:ItemDef[@OID=$valueDefOID]"/>
                
                <xsl:variable name="vlOID" select="../@OID"/>
                <xsl:variable name="parentDef" select="../../odm:ItemDef/def:ValueListRef[@ValueListOID=$vlOID]"/>
                <xsl:variable name="parentOID" select="$parentDef/../@OID"/>
                <xsl:variable name="ParentVName" select="$parentDef/../@Name"/>
                
                <xsl:variable name="ValueItemGroupOID"
                  select="$g_seqItemGroupDefs/odm:ItemRef[@ItemOID=$parentOID]/../@OID"/>
                
                <xsl:variable name="whereOID" select="./def:WhereClauseRef/@WhereClauseOID"/>
                <xsl:variable name="whereDef" select="$g_seqWhereClauseDefs[@OID=$whereOID]"/>
                <xsl:variable name="whereRefItemOID" select="$whereDef/odm:RangeCheck/@def:ItemOID"/>
                <xsl:variable name="whereRefItem"
                  select="$g_seqItemDefs[@OID=$whereRefItemOID]/@Name"/>
                <xsl:variable name="whereOP" select="$whereDef/odm:RangeCheck/@Comparator"/>
                <xsl:variable name="whereVal" select="$whereDef/odm:RangeCheck/odm:CheckValue"/>
                
                <xsl:element name="tr">
                  <xsl:attribute name="class">vlm<xsl:text> </xsl:text><xsl:value-of select="$VLMClass"/><xsl:text> </xsl:text><xsl:value-of select="$ParentItemDefOID"/>
                  </xsl:attribute>
                  
                  <!-- Source Variable column -->
                  <td>  
                    
                    <xsl:if test="$isSuppQual='0'">
                    </xsl:if>
                    
                    <xsl:if test="$isSuppQual='1'">
                      
                      <div class="qval-indent">
                        <xsl:text>&#x27A4;  </xsl:text>
                        <xsl:call-template name="displayWhereClause">
                          <xsl:with-param name="ValueItemRef" select="$ItemRef"/>
                          <xsl:with-param name="ItemGroupLink" select="$ValueItemGroupOID"/>
                          <xsl:with-param name="decode" select="0"/>
                          <xsl:with-param name="break" select="1"/>
                        </xsl:call-template>
                      </div>
                      
                    </xsl:if>

                    <xsl:if test="$isSuppQual='2'">
                      
                      <div class="qval-indent2">
                        <xsl:text>&#x27A4;  </xsl:text>
                        <xsl:call-template name="displayWhereClause">
                          <xsl:with-param name="ValueItemRef" select="$ItemRef"/>
                          <xsl:with-param name="ItemGroupLink" select="$ValueItemGroupOID"/>
                          <xsl:with-param name="decode" select="1"/>
                          <xsl:with-param name="break" select="1"/>
                        </xsl:call-template>
                      </div>  
                      
                    </xsl:if>  
                    
                    <!--  Define-XML v2.1 -->
                    <xsl:call-template name="displayNoData">
                      <xsl:with-param name="element" select="'span'" />
                    </xsl:call-template>

                  </td>
                  
                  <!-- 'WhereClause' column -->
                  <xsl:if test="$isSuppQual='0'">
                    <td>
                      
                      <xsl:call-template name="displayWhereClause">
                        <xsl:with-param name="ValueItemRef" select="$ItemRef"/>
                        <xsl:with-param name="ItemGroupLink" select="$ValueItemGroupOID"/>
                        <xsl:with-param name="decode" select="1"/>
                        <xsl:with-param name="break" select="1"/>
                      </xsl:call-template>
                      
                    </td>
                  </xsl:if>  
                                    
                  <!-- Label column for SuppQuals -->
                  <xsl:choose>
                    <xsl:when test="$isSuppQual='1'">
                    <td>
                      <xsl:if test="$valueDef/odm:Description/odm:TranslatedText">
                        <xsl:value-of select="$valueDef/odm:Description/odm:TranslatedText"/>
                      </xsl:if>
                    </td>
                  </xsl:when>
                  <xsl:when test="$isSuppQual='2'">
                    <td>
                      <xsl:if test="$valueDef/odm:Description/odm:TranslatedText">
                        <xsl:value-of select="$valueDef/odm:Description/odm:TranslatedText"/>
                      </xsl:if>
                    </td>
                  </xsl:when>
                  <xsl:otherwise>
                    <td>
                      <xsl:if test="$valueDef/odm:Description/odm:TranslatedText">
                        <xsl:value-of select="$valueDef/odm:Description/odm:TranslatedText"/>
                      </xsl:if>
                    </td>
                  </xsl:otherwise>
                  </xsl:choose>
                  
                  <!-- Datatype -->
                  <td class="datatype">
                    <xsl:value-of select="$valueDef/@DataType"/>
                  </td>
                  
                  <!-- Role (when defined) -->
                  <xsl:if test="count($ItemRef/@Role) > 0 or $addRoleColumn='1'">
                    <td class="role"><xsl:value-of select="$ItemRef/@Role"/></td>
                  </xsl:if>
                  
                  <!-- Length [Significant Digits] : DisplayFormat -->
                  <xsl:choose>
                    <xsl:when test="$displayLengthDFormatSD='1'">
                      <td class="number">
                        <xsl:call-template name="displayItemDefLengthSignDigitsDisplayFormat">
                          <xsl:with-param name="ItemDef" select="$valueDef"/>
                        </xsl:call-template>
                      </td>
                    </xsl:when>
                    <xsl:otherwise>
                      <td class="number">
                        <xsl:call-template name="displayItemDefLengthDFormat">
                          <xsl:with-param name="ItemDef" select="$valueDef"/>
                        </xsl:call-template>
                      </td>
                    </xsl:otherwise>
                  </xsl:choose>
                  
                  <!-- Controlled Terms or Format -->
                  <td>
                    <xsl:call-template name="displayItemDefDecodeList">
                      <xsl:with-param name="itemDef" select="$valueDef"/>
                    </xsl:call-template>
                    
                    <xsl:call-template name="displayItemDefISO8601">
                      <xsl:with-param name="itemDef" select="$valueDef"/>
                    </xsl:call-template>										
                  </td>
                  
                  <!-- Origin/Source/Method/Comment    -->
                  <td>
                    
                    <xsl:call-template name="displayItemDefOrigin">
                      <xsl:with-param name="itemDef" select="$valueDef"/>
                      <xsl:with-param name="OriginPrefix" select="$displayPrefix"/>
                    </xsl:call-template>
                    
                    <xsl:call-template name="displayItemDefMethod">
                      <xsl:with-param name="MethodOID" select="$ItemRef/@MethodOID"/>
                      <xsl:with-param name="MethodPrefix" select="$displayPrefix"/>
                    </xsl:call-template>
                    
                    <xsl:call-template name="displayComment">
                      <xsl:with-param name="CommentOID" select="$valueDef/@def:CommentOID"/>
                      <xsl:with-param name="CommentPrefix" select="$displayPrefix"/>
                    </xsl:call-template>
                    
                    <xsl:call-template name="displayComment">
                      <xsl:with-param name="CommentOID" select="$whereDef/@def:CommentOID"/>
                      <xsl:with-param name="CommentPrefix" select="$displayPrefix"/>
                    </xsl:call-template>
                    
                  </td>
                </xsl:element>
                <!-- end of loop over all def:ValueListDef elements -->


                <xsl:if test="$valueDef/def:ValueListRef/@ValueListOID and $isSuppQual = '1'">
                  <xsl:call-template name="tableValueListsInTable">
                    <xsl:with-param name="OID"
                      select="$valueDef/def:ValueListRef/@ValueListOID"/>
                    <xsl:with-param name="ParentItemDefOID"
                      select="$ParentItemDefOID"/>
                    <xsl:with-param name="addRoleColumn"
                      select="$addRoleColumn"/>
                    <xsl:with-param name="isSuppQual"
                      select="'2'"/>
                    <xsl:with-param name="VLMClass"
                      select="$VLMClass"/>
                  </xsl:call-template>
                </xsl:if>
                
              </xsl:for-each>
            
              <!-- end of loop over all ValueListDefs -->
          
        </xsl:for-each>
      
  </xsl:template>
  
  <!-- ***************************************** -->
  <!-- CodeLists                                 -->
  <!-- ***************************************** -->
  <xsl:template name="tableCodeLists">

    <xsl:if test="$g_seqCodeLists[odm:CodeListItem|odm:EnumeratedItem]">

      <a id="decodelist"/>
      <div class="containerbox">
        <h1 class="header">CodeLists</h1>

        <xsl:for-each select="$g_seqCodeLists[odm:CodeListItem|odm:EnumeratedItem]">

          <xsl:choose>
            <xsl:when test="./odm:CodeListItem">
              <xsl:call-template name="tableCodeListItems"/>
            </xsl:when>
            <xsl:when test="./odm:EnumeratedItem">
              <xsl:call-template name="tableEnumeratedItems"/>
            </xsl:when>
            <xsl:otherwise />
          </xsl:choose>

        </xsl:for-each>

        <xsl:call-template name="linkTop"/>
        <xsl:call-template name="lineBreak"/>
        
      </div>
    </xsl:if>
  </xsl:template>

  <!-- ***************************************** -->
  <!-- Display CodeList Items table              -->
  <!-- ***************************************** -->
  <xsl:template name="tableCodeListItems">
    <xsl:variable name="n_extended" select="count(odm:CodeListItem/@def:ExtendedValue)"/>
    
    <div class="codelist">
      <xsl:attribute name="id">CL.<xsl:value-of select="@OID"/></xsl:attribute>
      
      <div class="codelist-caption">
        <xsl:value-of select="@Name"/>
        <xsl:if test="./odm:Alias/@Context = 'nci:ExtCodeID'">
          <xsl:text> [</xsl:text>
          <span class="nci"><xsl:value-of select="./odm:Alias/@Name"/></span>
          <xsl:text>]</xsl:text>
        </xsl:if>
        
        <!--  Define-XML v2.1 -->
        <xsl:call-template name="displayStandard">
          <xsl:with-param name="element" select="'span'" />
        </xsl:call-template>  
        <!--  Define-XML v2.1 -->
        <xsl:call-template name="displayNonStandard">
          <xsl:with-param name="element" select="'span'" />
        </xsl:call-template>  
        
        <xsl:call-template name="displayDescription"/>
        
        <!--  Define-XML v2.1 -->
        <xsl:if test="@def:CommentOID">
          <div class="description">
            <xsl:call-template name="displayComment">
              <xsl:with-param name="CommentOID" select="@def:CommentOID" />
              <xsl:with-param name="CommentPrefix" select="$displayPrefix" />
              <xsl:with-param name="element" select="'div'" />
            </xsl:call-template>
          </div>
        </xsl:if>
      </div>
      
      <xsl:element name="table">
        <xsl:attribute name="summary">Controlled Term - <xsl:value-of select="@Name"/></xsl:attribute>
        
        <tr class="header">
          <th scope="col" class="codedvalue">Permitted Value (Code)</th>
          <th scope="col">Display Value (Decode)</th>
          <!--  Define-XML v2.1 -->
          <xsl:if test="./odm:CodeListItem/odm:Description/odm:TranslatedText">
            <th scope="col">Description</th>
          </xsl:if>
          <xsl:if test="./odm:CodeListItem/@Rank">
            <th scope="col">Rank</th>
          </xsl:if>
        </tr>
        
        <xsl:for-each select="./odm:CodeListItem">
          <xsl:sort data-type="number" select="@OrderNumber" order="ascending"/>
          <xsl:sort data-type="number" select="@Rank" order="ascending"/>
          <xsl:element name="tr">
            
            <xsl:call-template name="setRowClassOddeven">
              <xsl:with-param name="rowNum" select="position()"/>
            </xsl:call-template>
            <td>
              <xsl:value-of select="@CodedValue"/>
              <xsl:if test="./odm:Alias/@Context = 'nci:ExtCodeID'">
                <xsl:text> [</xsl:text>
                <span class="nci"><xsl:value-of select="./odm:Alias/@Name"/></span>
                <xsl:text>]</xsl:text> 
              </xsl:if>
              <xsl:if test="@def:ExtendedValue='Yes'">
                <xsl:text> [</xsl:text>
                <span class="extended">*</span>
                <xsl:text>]</xsl:text>
              </xsl:if>                            
            </td>
            <td class="codelist-item-decode">
              <xsl:value-of select="./odm:Decode/odm:TranslatedText"/>
            </td>
            <xsl:if test="../odm:CodeListItem/odm:Description/odm:TranslatedText">
            <td>
              <xsl:call-template name="displayItemDescription"/>              
            </td>
            </xsl:if>
            <xsl:if test="../odm:CodeListItem/@Rank">
              <td><xsl:value-of select="@Rank"/></td>
            </xsl:if>  
          </xsl:element>
        </xsl:for-each>
      </xsl:element>
      <xsl:if test="$n_extended &gt; 0">
        <p class="footnote"><span class="super">*</span> Extended Value</p>
      </xsl:if>
      
    </div>
  </xsl:template>
  
  <!-- ***************************************** -->
  <!-- Display Enumerated Items Table            -->
  <!-- ***************************************** -->
  <xsl:template name="tableEnumeratedItems">
    <xsl:variable name="n_extended" select="count(odm:EnumeratedItem/@def:ExtendedValue)"/>
    
    <div class="codelist">
      <xsl:attribute name="id">CL.<xsl:value-of select="@OID"/></xsl:attribute>
      
      <div class="codelist-caption">
        <xsl:value-of select="@Name"/>
        <xsl:if test="./odm:Alias/@Context = 'nci:ExtCodeID'">
          <xsl:text> [</xsl:text>
          <span class="nci"><xsl:value-of select="./odm:Alias/@Name"/></span>
          <xsl:text>]</xsl:text>
        </xsl:if>
        
        <!--  Define-XML v2.1 -->
        <xsl:call-template name="displayStandard">
          <xsl:with-param name="element" select="'span'" />
        </xsl:call-template>  
        <!--  Define-XML v2.1 -->
        <xsl:call-template name="displayNonStandard">
          <xsl:with-param name="element" select="'span'" />
        </xsl:call-template>  
        
        <xsl:call-template name="displayDescription"/>
        
        <!--  Define-XML v2.1 -->
        <xsl:if test="@def:CommentOID">
          <div class="description">
            <xsl:call-template name="displayComment">
              <xsl:with-param name="CommentOID" select="@def:CommentOID" />
              <xsl:with-param name="CommentPrefix" select="$displayPrefix" />
              <xsl:with-param name="element" select="'div'" />
            </xsl:call-template>
          </div>
        </xsl:if>
      </div>
      
      <xsl:element name="table">
        <xsl:attribute name="summary">Code List - <xsl:value-of select="@Name"/></xsl:attribute>
        
        <tr class="header">
          <th scope="col">Permitted Value (Code)</th>
          <xsl:if test="./odm:EnumeratedItem/odm:Description/odm:TranslatedText">
            <th scope="col">Description</th>
          </xsl:if>
          <xsl:if test="./odm:EnumeratedItem/@Rank">
            <th scope="col">Rank</th>
          </xsl:if>
        </tr>
        
        <xsl:for-each select="./odm:EnumeratedItem">
          <xsl:sort data-type="number" select="@OrderNumber" order="ascending"/>
          <xsl:sort data-type="number" select="@Rank" order="ascending"/>
          
          <xsl:element name="tr">
            <xsl:call-template name="setRowClassOddeven">
              <xsl:with-param name="rowNum" select="position()"/>
            </xsl:call-template>
            <td>
              <xsl:value-of select="@CodedValue"/>
              <xsl:if test="./odm:Alias/@Context = 'nci:ExtCodeID'">
                <xsl:text> [</xsl:text>
                <span class="nci"><xsl:value-of select="./odm:Alias/@Name"/></span>
                <xsl:text>]</xsl:text> 
              </xsl:if>
              <xsl:if test="@def:ExtendedValue='Yes'">
                <xsl:text> [</xsl:text>
                <span class="extended">*</span>
                <xsl:text>]</xsl:text>
              </xsl:if>
            </td>
            <!--  Define-XML v2.1 -->
            <xsl:if test="../odm:EnumeratedItem/odm:Description/odm:TranslatedText">
              <td>
                <xsl:call-template name="displayItemDescription"/>              
              </td>
            </xsl:if>
            <xsl:if test="../odm:EnumeratedItem/@Rank">
              <td><xsl:value-of select="@Rank"/></td>
            </xsl:if>  
          </xsl:element>
        </xsl:for-each>
      </xsl:element>
      <xsl:if test="$n_extended &gt; 0">
        <p class="footnote"><span class="super">*</span> Extended Value</p>
      </xsl:if>
    </div>
  </xsl:template>
  
  
  <!-- ***************************************** -->
  <!-- External Dictionaries                     -->
  <!-- ***************************************** -->
  <xsl:template name="tableExternalCodeLists">

    <xsl:if test="$g_seqCodeLists[odm:ExternalCodeList]">

      <a id="externaldictionary"/>
      <h1 class="invisible">External Dictionaries</h1>
      <div class="containerbox">

        <xsl:element name="table">
          <xsl:attribute name="summary">External Dictionaries (MedDra, WHODRUG, ...)</xsl:attribute>
          <caption class="header">External Dictionaries</caption>

          <tr class="header">
            <th scope="col">Reference Name</th>
            <th scope="col">External Dictionary</th>
            <th scope="col">Dictionary Version</th>
          </tr>

          <xsl:for-each select="$g_seqCodeLists/odm:ExternalCodeList">

            <xsl:element name="tr">

              <!-- Create an anchor -->
              <xsl:attribute name="id">CL.<xsl:value-of select="../@OID"/></xsl:attribute>

              <xsl:call-template name="setRowClassOddeven">
                <xsl:with-param name="rowNum" select="position()"/>
              </xsl:call-template>

              <td><xsl:value-of select="../@Name"/>

              <xsl:if test="../odm:Description/odm:TranslatedText">
                <div class="description"><xsl:value-of select="../odm:Description/odm:TranslatedText"/></div> 
              </xsl:if>
 
                <!--  Define-XML v2.1 -->
                <xsl:if test="../@def:CommentOID">
                <div class="description">
                  <xsl:call-template name="displayComment">
                    <xsl:with-param name="CommentOID" select="../@def:CommentOID" />
                    <xsl:with-param name="CommentPrefix" select="$displayPrefix" />
                    <xsl:with-param name="element" select="'div'" />
                  </xsl:call-template>
                </div>
              </xsl:if>
                
              </td>
              <td>
                <xsl:choose>
                  <xsl:when test="@href">
                    <xsl:call-template name="displayHyperlink">
                      <xsl:with-param name="href" select="@href"/>
                      <xsl:with-param name="anchor" select="''"/>
                      <xsl:with-param name="title" select="@Dictionary"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="@Dictionary"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                  <xsl:when test="@ref">
                    <xsl:text> (</xsl:text>
                    <xsl:call-template name="displayHyperlink">
                      <xsl:with-param name="href" select="@ref"/>
                      <xsl:with-param name="anchor" select="''"/>
                      <xsl:with-param name="title" select="@ref"/>
                    </xsl:call-template>
                    <xsl:text>)</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
              <td><xsl:value-of select="@Version"/></td>

            </xsl:element>
          </xsl:for-each>
        </xsl:element>
      </div>
      
      <xsl:call-template name="linkTop"/>
      <xsl:call-template name="lineBreak"/>
      
    </xsl:if>
  </xsl:template>

  <!-- *************************************************************** -->
  <!-- Methods                                                         -->
  <!-- *************************************************************** -->
  <xsl:template name="tableMethods">

    <xsl:if test="$g_seqMethodDefs">

      <a id="compmethod"/>
      <div class="containerbox">

        <h1 class="invisible">Methods</h1>

        <xsl:element name="table">
          <xsl:attribute name="summary">Methods</xsl:attribute>
          <caption class="header">Methods</caption>

          <tr class="header">
            <th scope="col">Method</th>
            <th scope="col">Type</th>
            <th scope="col">Description</th>
          </tr>
          <xsl:for-each select="$g_seqMethodDefs">

            <xsl:element name="tr">

              <!-- Create an anchor -->
              <xsl:attribute name="id">MT.<xsl:value-of select="@OID"/></xsl:attribute>

              <xsl:call-template name="setRowClassOddeven">
                <xsl:with-param name="rowNum" select="position()"/>
              </xsl:call-template>

              <td>
                <xsl:value-of select="@Name"/>
              </td>
              <td>
                <xsl:value-of select="@Type"/>
              </td>
              <td>
                <div class="method-code"><xsl:value-of select="./odm:Description/odm:TranslatedText"/></div>
 
                <xsl:if test="string-length(./odm:FormalExpression) &gt; 0">
                  <xsl:for-each select="odm:FormalExpression">
                    <div class="formalexpression">
                      <span class="label">Formal Expression</span>
                      <xsl:if test="string-length(@Context) &gt; 0">
                        <xsl:text> [</xsl:text>
                        <xsl:value-of select="@Context"/>
                        <xsl:text>]</xsl:text>
                      </xsl:if>
                      <xsl:text>:</xsl:text>
                      <span class="formalexpression-code"><xsl:value-of select="."/></span>
                    </div>
                  </xsl:for-each>
                </xsl:if>

                <xsl:for-each select="./def:DocumentRef">
                  <xsl:call-template name="displayDocumentRef"/>
                </xsl:for-each>
                
              </td>
            </xsl:element>
          </xsl:for-each>
        </xsl:element>
      </div>
      
      <xsl:call-template name="linkTop"/>
      <xsl:call-template name="lineBreak"/>
      
    </xsl:if>
  </xsl:template>

  <!-- *************************************************************** -->
  <!-- Comments                                                        -->
  <!-- *************************************************************** -->
  <xsl:template name="tableComments">

    <xsl:if test="$g_seqCommentDefs">

      <a id="comment"/>
      <div class="containerbox">
        <h1 class="invisible">Comments</h1>

        <xsl:element name="table">
          <xsl:attribute name="summary">Comments</xsl:attribute>
          <caption class="header">Comments</caption>
          <!-- set the legend (title) -->

          <tr class="header">
            <th scope="col">CommentOID</th>
            <th scope="col">Description</th>
          </tr>
          <xsl:for-each select="$g_seqCommentDefs">
            <xsl:element name="tr">

              <!-- Create an anchor -->
              <xsl:attribute name="id">COMM.<xsl:value-of select="@OID"/></xsl:attribute>

              <xsl:call-template name="setRowClassOddeven">
                <xsl:with-param name="rowNum" select="position()"/>
              </xsl:call-template>

              <td>
                <xsl:value-of select="@OID"/>
              </td>
              <td>
                
                <xsl:value-of select="normalize-space(.)"/>
                
                <xsl:for-each select="./def:DocumentRef">
                  <xsl:call-template name="displayDocumentRef"/>
                </xsl:for-each>
                
              </td>
            </xsl:element>
          </xsl:for-each>
        </xsl:element>
      </div>
      
      <xsl:call-template name="linkTop"/>
      <xsl:call-template name="lineBreak"/>
      
    </xsl:if>
  </xsl:template>

  <!-- *************************************************** -->
  <!-- Templates for special features like hyperlinks      -->
  <!-- *************************************************** -->

  <!-- *************************************************************** -->
  <!-- Document References                                             -->
  <!-- *************************************************************** -->
  <xsl:template name="displayDocumentRef">
    
    <xsl:param name="element" select="'p'"/>
    
    <xsl:variable name="leafID" select="@leafID"/>
    <xsl:variable name="leaf" select="$g_seqleafs[@ID = $leafID]"/>
    <xsl:variable name="href" select="$leaf/@xlink:href"/>
    
    <xsl:choose>
      <xsl:when test="def:PDFPageRef">
        <xsl:for-each select="def:PDFPageRef">
          <xsl:variable name="title">
            <xsl:choose>
              <xsl:when test="count($leaf) = 0">
                <span class="unresolved">[unresolved: <xsl:value-of select="$leafID"/></span>]
              </xsl:when>
              <!--  Define-XML v2.1 -->
              <xsl:when test="@Title">
                <xsl:value-of select="@Title"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$leaf/def:title"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="PageRefType" select="normalize-space(@Type)"/>
          <xsl:variable name="PageRefs" select="normalize-space(@PageRefs)"/>
          <xsl:variable name="PageFirst" select="normalize-space(@FirstPage)"/>
          <xsl:variable name="PageLast" select="normalize-space(@LastPage)"/>
          
          <xsl:element name="{$element}">  
            <xsl:attribute name="class">
              <xsl:text>linebreakcell</xsl:text>
            </xsl:attribute>

            <xsl:choose>
              <xsl:when test="$PageRefType = $REFTYPE_PHYSICALPAGE">
                <xsl:call-template name="linkPages2Hyperlinks">
                  <xsl:with-param name="href" select="$href"/>
                  <xsl:with-param name="pagenumbers">
                    <xsl:choose>
                      <xsl:when test="$PageRefs"><xsl:value-of select="normalize-space($PageRefs)"/>
                      </xsl:when>
                      <xsl:when test="$PageFirst"><xsl:value-of select="normalize-space(concat($PageFirst, '-', $PageLast))"/>
                      </xsl:when>
                      <xsl:otherwise>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:with-param>
                  <xsl:with-param name="title" select="$title"/>
                  <xsl:with-param name="ShowTitle" select="1"/>
                  <xsl:with-param name="Separator">
                    <xsl:choose>
                      <xsl:when test="$PageRefs"><xsl:value-of select="' '"/>
                      </xsl:when>
                      <xsl:when test="$PageFirst"><xsl:value-of select="'-'"/>
                      </xsl:when>
                      <xsl:otherwise>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:with-param>
                  
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="$PageRefType = $REFTYPE_NAMEDDESTINATION">
                <xsl:call-template name="linkNamedDestinations2Hyperlinks">
                  <xsl:with-param name="href" select="$href"/>
                  <xsl:with-param name="destinations" select="$PageRefs"/>
                  <xsl:with-param name="title" select="$title"/>
                  <xsl:with-param name="ShowTitle" select="1"/>
                  <xsl:with-param name="Separator" select="' '"/>
                </xsl:call-template>
              </xsl:when>
            </xsl:choose>

          </xsl:element>
        </xsl:for-each>        
      </xsl:when>
      <xsl:otherwise>
        
        <xsl:variable name="title">
          <xsl:choose>
            <xsl:when test="count($leaf) = 0">
              <span class="unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$leafID"/><xsl:text>]</xsl:text></span>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$leaf/def:title"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:element name="{$element}">  
          <xsl:attribute name="class">
            <xsl:text>linebreakcell</xsl:text>
          </xsl:attribute>
          <xsl:call-template name="displayHyperlink">
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="anchor" select="''"/>
            <xsl:with-param name="title" select="$title"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>
  
  <!-- ******************************************************** -->
  <!-- Hypertext Link to CRF Pages (if necessary)               -->
  <!-- New mechanism: transform all numbers found in the string -->
  <!-- to hyperlinks                                            -->
  <!-- ******************************************************** -->
  <xsl:template name="linkPages2Hyperlinks">
    <xsl:param name="href"/>
    <xsl:param name="pagenumbers"/>
    <xsl:param name="title"/>
    <xsl:param name="ShowTitle"/>
    <xsl:param name="Separator"/>
    
    <xsl:variable name="OriginString" select="$pagenumbers"/>
    <xsl:variable name="first">
      <xsl:choose>
        <xsl:when test="contains($OriginString,$Separator)">
          <xsl:value-of select="substring-before($OriginString,$Separator)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$OriginString"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="rest" select="substring-after($OriginString,$Separator)"/>
    <xsl:variable name="stringlengthfirst" select="string-length($first)"/>
    
    <xsl:if test="$ShowTitle != '0'">
      <xsl:value-of select="$title"/>
      <xsl:text> [</xsl:text>
    </xsl:if>  
    
    <xsl:if test="string-length($first) > 0">
      <xsl:choose>
        <xsl:when test="number($first)">
          <!-- it is a number, create the hyperlink -->
          <xsl:call-template name="displayHyperlink">
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="anchor" select="concat('#page=', $first)"/>
            <xsl:with-param name="title" select="$first"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <!-- it is not a number -->
          <xsl:value-of select="$first"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    
    <!-- split up the second part in words (recursion) -->
    <xsl:if test="string-length($rest) > 0">
      
      <xsl:choose>
        <xsl:when test="contains($rest,$Separator)">
          <xsl:call-template name="linkPages2Hyperlinks">
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="pagenumbers" select="$rest"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="ShowTitle" select="0"/>
            <xsl:with-param name="Separator" select="' '"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text> </xsl:text>
          <xsl:value-of select="$Separator"/>
          <xsl:text> </xsl:text>
          
          <xsl:choose>
            <xsl:when test="number($rest)">
              <!-- it is a number, create the hyperlink -->
              <xsl:call-template name="displayHyperlink">
                <xsl:with-param name="href" select="$href"/>
                <xsl:with-param name="anchor" select="concat('#page=', $rest)"/>
                <xsl:with-param name="title" select="$rest"/>
              </xsl:call-template>
              <xsl:text>]</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <!-- it is not a number -->
              <xsl:value-of select="$rest"/>
              <xsl:text>]</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    
    <xsl:if test="string-length($rest) = 0">
      <xsl:text>]</xsl:text>
    </xsl:if>
    
  </xsl:template>

  <!-- ******************************************************** -->
  <!-- Hypertext Link to Named Destinations (if necessary)      -->
  <!-- ******************************************************** -->
  <xsl:template name="linkNamedDestinations2Hyperlinks">
    <xsl:param name="href"/>
    <xsl:param name="destinations"/>
    <xsl:param name="title"/>
    <xsl:param name="ShowTitle"/>
    <xsl:param name="Separator"/>
    
    <xsl:variable name="OriginString" select="$destinations"/>
    <xsl:variable name="first">
      <xsl:choose>
        <xsl:when test="contains($OriginString,$Separator)">
          <xsl:value-of select="substring-before($OriginString,$Separator)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$OriginString"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="rest" select="substring-after($OriginString,$Separator)"/>
    <xsl:variable name="stringlengthfirst" select="string-length($first)"/>
    
    <xsl:if test="$ShowTitle != '0'">
      <xsl:value-of select="$title"/>
      <xsl:text> [</xsl:text>
    </xsl:if>  
    
    <xsl:if test="string-length($first) > 0">
      <xsl:call-template name="displayHyperlink">
        <xsl:with-param name="href" select="$href"/>
        <xsl:with-param name="anchor" select="concat('#', $first)"/>
        <xsl:with-param name="title">
          <xsl:call-template name="stringReplace">
            <!-- Replace occurrences of #20 with blanks -->
            <xsl:with-param name="string" select="$first"/>
            <xsl:with-param name="from" select="'#20'"/>
            <xsl:with-param name="to" select="' '"/>
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    
    <!-- split up the second part in words (recursion) -->
    <xsl:if test="string-length($rest) > 0">
      
      <xsl:choose>
        <xsl:when test="contains($rest,$Separator)">
          <xsl:call-template name="linkNamedDestinations2Hyperlinks">
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="destinations" select="$rest"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="ShowTitle" select="0"/>
            <xsl:with-param name="Separator" select="' '"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text> </xsl:text>
          <xsl:value-of select="$Separator"/>
          <xsl:text> </xsl:text>
          
          <xsl:call-template name="displayHyperlink">
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="anchor" select="concat('#', $rest)"/>
            <xsl:with-param name="title">
              <!-- Replace occurrences of #20 with blanks -->
              <xsl:call-template name="stringReplace">
                <xsl:with-param name="string" select="$rest"/>
                <xsl:with-param name="from" select="'#20'"/>
                <xsl:with-param name="to" select="' '"/>
              </xsl:call-template>
            </xsl:with-param>
          </xsl:call-template>
          <xsl:text>]</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    
    <xsl:if test="string-length($rest) = 0">
      <xsl:text>]</xsl:text>
    </xsl:if>
    
  </xsl:template>
  
  <!-- ******************************************************** -->
  <!-- Hypertext Link to a Document                             -->
  <!-- ******************************************************** -->
  <xsl:template name="displayHyperlink">
    <xsl:param name="href"/>
    <xsl:param name="anchor"/>
    <xsl:param name="title"/>
    <!-- create the hyperlink itself -->
    <xsl:choose>
      <xsl:when test="$href">
        <a class="external">
          <xsl:attribute name="href">
            <xsl:value-of select="concat($href, $anchor)"/>
          </xsl:attribute>
          <xsl:value-of select="$title"/>          
        </a>
        <xsl:call-template name="displayImage" />
        <xsl:text> </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$title"/>
        <xsl:call-template name="displayImage" />
        <xsl:text> </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
 

  <!-- ************************************************************* -->
  <!-- Link to Parent Domain                                         -->
  <!-- ************************************************************* -->
  <xsl:template name="linkParentDomain">

    <!-- REMARK that we are still in the 'ItemRef' template
             but at the 'ItemGroupDef' level -->

    <xsl:if test="starts-with(@Name, 'SUPP')">
      <!-- create an extra row to the XX dataset when there is one -->
      <xsl:variable name="parentDatasetName" select="substring(@Name, 5)"/>
      <xsl:if test="../odm:ItemGroupDef[@Name = $parentDatasetName]">
        <xsl:variable name="datasetOID" select="../odm:ItemGroupDef[@Name = $parentDatasetName]/@OID"/>
        <tr>
          <td colspan="8">
            <xsl:text>Related Parent Dataset: </xsl:text>
            <a>
              <xsl:attribute name="href">#IG.<xsl:value-of select="$datasetOID"/></xsl:attribute>
              <xsl:value-of select="$parentDatasetName"/>
            </a>
            <xsl:text> (</xsl:text>
            <xsl:value-of select="//odm:ItemGroupDef[@OID = $datasetOID]/odm:Description/odm:TranslatedText"/>
            <xsl:text>)</xsl:text>
          </td>
        </tr>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Link to Associated Persons Parent Domain                      -->
  <!-- ************************************************************* -->
  <xsl:template name="linkApParentDomain">
    
    <!-- REMARK that we are still in the 'ItemRef' template
             but at the 'ItemGroupDef' level -->
    
    <xsl:if test="starts-with(@Name, 'SQAP')">
      <!-- create an extra row to the XX dataset when there is one -->
      <xsl:variable name="parentDatasetName" select="concat('AP', substring(@Name, 5))"/>
      <xsl:if test="../odm:ItemGroupDef[@Name = $parentDatasetName]">
        <xsl:variable name="datasetOID" select="../odm:ItemGroupDef[@Name = $parentDatasetName]/@OID"/>
        <tr>
          <td colspan="8">
            <xsl:text>Related Parent Dataset: </xsl:text>
            <a>
              <xsl:attribute name="href">#IG.<xsl:value-of select="$datasetOID"/></xsl:attribute>
              <xsl:value-of select="$parentDatasetName"/>
            </a>
            <xsl:text> (</xsl:text>
            <xsl:value-of select="//odm:ItemGroupDef[@OID = $datasetOID]/odm:Description/odm:TranslatedText"/>
            <xsl:text>)</xsl:text>
          </td>
        </tr>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Link to Supplemental Qualifiers                               -->
  <!-- ************************************************************* -->
  <xsl:template name="linkSuppQual">
    
    <!-- REMARK that we are still in the 'ItemRef' template
             but at the 'ItemGroupDef' level -->

    <xsl:variable name="suppDatasetName" select="concat('SUPP', @Name)"/>
    
    <xsl:if test="../odm:ItemGroupDef[@Name = $suppDatasetName]">
      <!-- create an extra row to the SUPPXX dataset when there is one -->
      <xsl:variable name="datasetOID" select="../odm:ItemGroupDef[@Name = $suppDatasetName]/@OID"/>
      <tr>
        <td colspan="8">
          <xsl:text>Related Supplemental Qualifiers Dataset: </xsl:text>
          <a>
            <xsl:attribute name="href">#IG.<xsl:value-of select="$datasetOID"/></xsl:attribute>
            <xsl:value-of select="$suppDatasetName"/>
          </a>
          <xsl:text> (</xsl:text>
          <xsl:value-of select="//odm:ItemGroupDef[@OID = $datasetOID]/odm:Description/odm:TranslatedText"/>
          <xsl:text>)</xsl:text>
        </td>
      </tr>
    </xsl:if>
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Link to Associated Domain Supplemental Qualifiers             -->
  <!-- ************************************************************* -->
  <xsl:template name="linkSQAP">
    
    <!-- REMARK that we are still in the 'ItemRef' template
             but at the 'ItemGroupDef' level -->
    
    <xsl:if test="substring(@Name, 1, 2)='AP'">
      <xsl:variable name="suppDatasetName" select="concat('SQAP', substring(@Name, 3))"/>
      
      <xsl:if test="../odm:ItemGroupDef[@Name = $suppDatasetName]">
        <!-- create an extra row to the SUPPXX dataset when there is one -->
        <xsl:variable name="datasetOID" select="../odm:ItemGroupDef[@Name = $suppDatasetName]/@OID"/>
        <tr>
          <td colspan="8">
            <xsl:text>Related Supplemental Qualifiers Dataset: </xsl:text>
            <a>
              <xsl:attribute name="href">#IG.<xsl:value-of select="$datasetOID"/></xsl:attribute>
              <xsl:value-of select="$suppDatasetName"/>
            </a>
            <xsl:text> (</xsl:text>
            <xsl:value-of select="//odm:ItemGroupDef[@OID = $datasetOID]/odm:Description/odm:TranslatedText"/>
            <xsl:text>)</xsl:text>
          </td>
        </tr>
      </xsl:if>
    </xsl:if>  
  </xsl:template>
  
  
  <!-- ************************************************************* -->
  <!-- Get Parent Dataset Description                                -->
  <!-- ************************************************************* -->
  <xsl:template name="getParentDescription">  
    
    <xsl:param name="OID" />
    
    <xsl:variable name="Domain" select="$g_seqItemGroupDefs[@OID=$OID]/@Domain"/>
    <xsl:variable name="Name" select="$g_seqItemGroupDefs[@OID=$OID]/@Name"/>
    <xsl:variable name="ParentDescription" select="$g_seqItemGroupDefs[@Domain = $Domain and @Domain = @Name and @Name != $Name]/odm:Description/odm:TranslatedText"/>
        
    <xsl:choose>
      <xsl:when test="odm:Alias[@Context='DomainDescription']">
        <xsl:value-of select="odm:Alias/@Name"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$ParentDescription"/>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:template>  
  
  <!-- ************************************************************* -->
  <!-- Display Comment                                               -->
  <!-- ************************************************************* -->
  <xsl:template name="displayComment">

    <xsl:param name="CommentOID" />
    <xsl:param name="CommentPrefix"/>
    <xsl:param name="element" select="'p'"/>
    
    <xsl:if test="$CommentOID">
      <xsl:variable name="Comment" select="$g_seqCommentDefs[@OID=$CommentOID]"/>
      <xsl:variable name="CommentTranslatedText">
        <xsl:value-of select="normalize-space($g_seqCommentDefs[@OID=$CommentOID]/odm:Description/odm:TranslatedText)"/>
      </xsl:variable> 
 
      <xsl:element name="{$element}">  
        <xsl:attribute name="class">
          <xsl:text>linebreakcell</xsl:text>
        </xsl:attribute>
        <xsl:choose>
          <xsl:when test="string-length($CommentTranslatedText) &gt; 0">
            <xsl:if test="$CommentPrefix != '0'">
              <span class="prefix"><xsl:value-of select="$PREFIX_COMMENT_TEXT"/></span>
            </xsl:if>  
            <xsl:value-of select="$CommentTranslatedText"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$CommentPrefix != '0'">
              <span class="prefix"><xsl:value-of select="$PREFIX_COMMENT_TEXT"/></span>
            </xsl:if>  
            <span class="unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$CommentOID"/><xsl:text>]</xsl:text></span>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
      
      <xsl:for-each select="$Comment/def:DocumentRef">
        <xsl:call-template name="displayDocumentRef">
          <xsl:with-param name="element" select="$element" />
        </xsl:call-template>
      </xsl:for-each>
      
    </xsl:if>
  </xsl:template>

  <!-- ***************************************** -->
  <!-- Display Description                       -->
  <!-- ***************************************** -->
  <xsl:template name="displayDescription">
    <xsl:if test="odm:Description/odm:TranslatedText">
      <br />
      <span class="description">
        <xsl:value-of select="odm:Description/odm:TranslatedText"/>
      </span>
    </xsl:if>
  </xsl:template>
  
  <!-- ***************************************** -->
  <!-- Display Item Description                       -->
  <!-- ***************************************** -->
  <xsl:template name="displayItemDescription">
    <xsl:if test="odm:Description/odm:TranslatedText">
      <span class="itemdescription">
        <xsl:value-of select="odm:Description/odm:TranslatedText"/>
      </span>
    </xsl:if>
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display ItemDef Length                                        -->
  <!-- ************************************************************* -->
  <xsl:template name="displayItemDefLength">
    
    <xsl:param name="ItemDef"/>
    
    <xsl:choose>
      <xsl:when test="$ItemDef/@Length">
        <xsl:value-of select="$ItemDef/@Length"/>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display ItemDef Length / DisplayFormat                        -->
  <!-- ************************************************************* -->
  <xsl:template name="displayItemDefLengthDFormat">
    
    <xsl:param name="ItemDef"/>
    
    <xsl:choose>
      <xsl:when test="$ItemDef/@def:DisplayFormat">
        <xsl:value-of select="$ItemDef/@def:DisplayFormat"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$ItemDef/@Length"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display ItemDef Length [Significant Digits] : DisplayFormat   -->
  <!-- ************************************************************* -->
  <xsl:template name="displayItemDefLengthSignDigitsDisplayFormat">
    
    <xsl:param name="ItemDef"/>
    
    <xsl:choose>
      <xsl:when test="$ItemDef/@Length">
        <xsl:value-of select="$ItemDef/@Length"/>
        <xsl:if test="$ItemDef/@SignificantDigits">
          <xsl:text>  [</xsl:text>
          <xsl:value-of select="$ItemDef/@SignificantDigits"/>
          <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:if test="$ItemDef/@def:DisplayFormat">
          <xsl:text> : </xsl:text>
          <xsl:value-of select="$ItemDef/@def:DisplayFormat"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$ItemDef/@def:DisplayFormat">
          <xsl:value-of select="$ItemDef/@def:DisplayFormat"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display ItemDef Method                                        -->
  <!-- ************************************************************* -->
  <xsl:template name="displayItemDefMethod">
    
    <xsl:param name="MethodOID"/>
    <xsl:param name="MethodPrefix"/>
    
    <xsl:if test="$MethodOID">
      <xsl:variable name="Method" select="$g_seqMethodDefs[@OID=$MethodOID]"/>
      <xsl:variable name="MethodType" select="$g_seqMethodDefs[@OID=$MethodOID]/@Type"/>
      <xsl:variable name="MethodTranslatedText" select="$Method/odm:Description/odm:TranslatedText"/>
      <xsl:variable name="MethodFormalExpression" select="$Method/odm:FormalExpression"/>
      
      <div class="method-code">
        <xsl:choose>
          <xsl:when test="string-length($MethodTranslatedText) &gt; 0">
            <xsl:if test="$MethodPrefix = '1'">
              <span class="prefix"><xsl:value-of select="$PREFIX_METHOD_TEXT"/></span>
            </xsl:if>
            <xsl:value-of select="$MethodTranslatedText"/>
            <xsl:if test="$MethodFormalExpression">
              <span class="formalexpression-reference">
                <a>
                  <xsl:attribute name="href">#MT.<xsl:value-of select="$MethodOID"/></xsl:attribute>
                  <xsl:attribute name="title">Formal Expression</xsl:attribute>
                  <xsl:text>Formal Expression</xsl:text>
                </a>
              </span>  
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$MethodPrefix = '1'">
              <span class="prefix"><xsl:value-of select="$PREFIX_METHOD_TEXT"/></span>
            </xsl:if>
            <span class="unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$MethodOID"/><xsl:text>]</xsl:text></span>
          </xsl:otherwise>
        </xsl:choose>
     </div>

      <xsl:for-each select="$Method/def:DocumentRef">
        <xsl:call-template name="displayDocumentRef"/>
      </xsl:for-each>
      
    </xsl:if>
  </xsl:template>

  <!-- ******************************************************** -->
  <!-- Display ItemDef Origin                                   -->
  <!-- ******************************************************** -->
  <xsl:template name="displayItemDefOrigin">

    <xsl:param name="itemDef"/>
    <xsl:param name="OriginPrefix"/>
    
    <xsl:for-each select="$itemDef/def:Origin"> 	
      
      <xsl:variable name="OriginType" select="@Type"/>
      <!--  Define-XML v2.1 -->
      <xsl:variable name="OriginSource" select="@Source"/>
      <xsl:variable name="OriginDescription" select="./odm:Description/odm:TranslatedText"/>
            
      <div class="linebreakcell">
        <xsl:if test="$OriginPrefix != '0'">
          <span class="prefix"><xsl:value-of select="$PREFIX_ORIGIN_TEXT"/></span>
        </xsl:if>  
        <xsl:value-of select="$OriginType"/>
        
        <!--  Define-XML v2.1 -->
        <xsl:if test="$OriginSource">
          <xsl:text> (</xsl:text>
          <span class="linebreakcell">Source: <xsl:value-of select="$OriginSource"/></span>
          <xsl:text>)</xsl:text>
        </xsl:if>
        
        <xsl:if test="$OriginDescription">
          <xsl:choose>
            <!--  Define-XML v2.1 -->
            <xsl:when test="$OriginSource">
              <p class="linebreakcell">
                <xsl:value-of select="$OriginDescription"/>
              </p>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="$OriginType = 'Predecessor'">
                  <xsl:text>: </xsl:text>
                  <xsl:value-of select="$OriginDescription"/>
                </xsl:when>
                <xsl:otherwise>
                  <p class="linebreakcell">
                    <xsl:value-of select="$OriginDescription"/>
                  </p>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </div>

      <xsl:for-each select="def:DocumentRef">	
        <xsl:call-template name="displayDocumentRef"/>
      </xsl:for-each>  

      <xsl:if test="position() != last()">
        <br />
      </xsl:if>
      
    </xsl:for-each>  		
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Display ItemGroup Class                                        -->
  <!-- ************************************************************* -->
  <xsl:template name="displayItemGroupClass">
    
      <xsl:if test="@def:Class">
        <xsl:value-of select="@def:Class" />    
      </xsl:if>

    <xsl:if test="def:Class/@Name">
      <!--  Define-XML v2.1 (only one SubClass level supported currently) -->
      <xsl:variable name="ClassName" select="def:Class/@Name"/>
        <xsl:value-of select="$ClassName" />
        <xsl:if test="def:Class/def:SubClass/@Name">
          <ul class="SubClass">
            <xsl:for-each select="def:Class/def:SubClass[@ParentClass=$ClassName or not(@ParentClass)]">
              <li class="SubClass"><xsl:value-of select="@Name" /></li>
            </xsl:for-each>
          </ul>
        </xsl:if>
      </xsl:if>
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display ItemGroup Keys                                        -->
  <!-- ************************************************************* -->
  <xsl:template name="displayItemGroupKeys">
    <xsl:variable name="datasetName" select="@Name"/>
    <xsl:variable name="suppDatasetName" select="concat('SUPP', $datasetName)"/>
    <xsl:variable name="sqDatasetName" select="concat('SQ', $datasetName)"/>
    
    <xsl:variable name="ItemDef" select="$g_seqItemDefs[@Name='QVAL']" />
    <xsl:variable name="ItemDefValueListOID" select="$ItemDef[@OID=$g_seqItemGroupDefs[@Name = $suppDatasetName or @Name = $sqDatasetName]/odm:ItemRef/@ItemOID]/def:ValueListRef/@ValueListOID" />
    
    <xsl:for-each select="odm:ItemRef|$g_seqValueListDefs[@OID=$ItemDefValueListOID]/odm:ItemRef">
      <xsl:sort select="@KeySequence" data-type="number" order="ascending"/>
      <xsl:if test="@KeySequence[ .!='' ]">
      <xsl:variable name="ItemOID" select="@ItemOID"/>
      <xsl:variable name="Name" select="$g_seqItemDefs[@OID=$ItemOID]"/>
      <xsl:if test="../@OID = $ItemDefValueListOID">QNAM.</xsl:if>  
      <xsl:value-of select="$Name/@Name"/>
      <xsl:if test="position() != last()">, </xsl:if>
      </xsl:if>
    </xsl:for-each>
    
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Display ItemGroup Header                                      -->
  <!-- ************************************************************* -->
  <xsl:template name="displayItemGroupDefHeader">
    <xsl:value-of select="concat(@Name, ' (', ./odm:Description/odm:TranslatedText)"/>

    <xsl:variable name="ParentDescription">
      <xsl:call-template name="getParentDescription">
        <xsl:with-param name="OID" select="@OID" />
      </xsl:call-template>  
    </xsl:variable>
    <xsl:if test="string-length(normalize-space($ParentDescription)) &gt; 0">
      <xsl:text>, </xsl:text><xsl:value-of select="$ParentDescription"/><xsl:text></xsl:text>
    </xsl:if>
    <xsl:text>) - </xsl:text>
    
    <xsl:value-of select="@def:Class"/>
    <xsl:text> </xsl:text>
    
    <!--  Define-XML v2.1 -->
    <xsl:call-template name="displayStandard">
      <xsl:with-param name="element" select="'span'" />
    </xsl:call-template>  
    <!--  Define-XML v2.1 -->
    <xsl:call-template name="displayNonStandard">
      <xsl:with-param name="element" select="'span'" />
    </xsl:call-template>  
    <!--  Define-XML v2.1 -->
    <xsl:call-template name="displayNoData">
      <xsl:with-param name="element" select="'span'" />
    </xsl:call-template>  
    
    <xsl:variable name="archiveLocationID" select="@def:ArchiveLocationID"/>
    <xsl:variable name="archiveTitle">
      <xsl:choose>
        <xsl:when test="def:leaf[@ID=$archiveLocationID]">
          <xsl:value-of select="def:leaf[@ID=$archiveLocationID]/def:title"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>[unresolved: </xsl:text><xsl:value-of select="@def:ArchiveLocationID"/><xsl:text>]</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="@def:ArchiveLocationID">
      <span class="dataset">
        <xsl:text>Location: </xsl:text>
        <xsl:call-template name="displayHyperlink">
          <xsl:with-param name="href" select="def:leaf[@ID=$archiveLocationID]/@xlink:href"/>
          <xsl:with-param name="anchor" select="''"/>
          <xsl:with-param name="title" select="$archiveTitle"/>
        </xsl:call-template>
      </span>
    </xsl:if>
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Display Standard  (Define-XML v2.1)                           -->
  <!-- ************************************************************* -->
  <xsl:template name="displayStandard">
    
    <xsl:param name="element" select="'p'"/>
    <xsl:variable name="StandardOID" select="@def:StandardOID"/>
    <xsl:variable name="Standard" select="$g_seqStandard[@OID=$StandardOID]"/>
    
    <xsl:if test="$StandardOID">
       <xsl:element name="{$element}">  
        <xsl:attribute name="class">
          <xsl:text>standard-refeference</xsl:text>
        </xsl:attribute>
         <xsl:text>[</xsl:text>
         <xsl:value-of select="$Standard/@Name"/><xsl:text> </xsl:text>
         <xsl:if test="$Standard/@PublishingSet">
           <xsl:value-of select="$Standard/@PublishingSet"/><xsl:text> </xsl:text>
         </xsl:if>
         <xsl:value-of select="$Standard/@Version"/>
         <xsl:text>]</xsl:text>
      </xsl:element>
    </xsl:if>
    
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display NonStandard  (Define-XML v2.1)                        -->
  <!-- ************************************************************* -->
  <xsl:template name="displayNonStandard">
    
    <xsl:param name="element" select="'p'"/>
    
    <xsl:if test="@def:IsNonStandard='Yes'">
      <xsl:element name="{$element}">  
        <xsl:attribute name="class">
          <xsl:text>standard-refeference</xsl:text>
        </xsl:attribute>
        <xsl:text>[Non Standard]</xsl:text>
      </xsl:element>
    </xsl:if>
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display NoData (Define-XML v2.1)                              -->
  <!-- ************************************************************* -->
  <xsl:template name="displayNoData">
    
    <xsl:param name="element" select="'p'"/>
    
    <xsl:if test="@def:HasNoData='Yes'">
      <xsl:element name="{$element}">  
        <xsl:attribute name="class">
          <xsl:text>nodata</xsl:text>
        </xsl:attribute>
        <xsl:text>[No Data]</xsl:text>
      </xsl:element>
    </xsl:if>
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display WhereClause                                           -->
  <!-- ************************************************************* -->
  <xsl:template name="displayWhereClause">
    <xsl:param name="ValueItemRef"/>
    <xsl:param name="ItemGroupLink"/>
    <xsl:param name="decode"/>
    <xsl:param name="break"/>
    
    <xsl:variable name="ValueRef" select="$ValueItemRef"/>
    <xsl:variable name="Nwhereclauses" select="count(./def:WhereClauseRef)"/>
    
    <xsl:for-each select="$ValueRef/def:WhereClauseRef">
    
      <xsl:if test="$Nwhereclauses &gt; 1"><xsl:text>(</xsl:text></xsl:if>
      <xsl:variable name="whereOID" select="./@WhereClauseOID"/>
      <xsl:variable name="whereDef" select="$g_seqWhereClauseDefs[@OID=$whereOID]"/>
      
      <xsl:if test="count($g_seqWhereClauseDefs[@OID=$whereOID])=0">
        <span class="unresolved">[unresolved: <xsl:value-of select="$whereOID"/>]</span>
      </xsl:if>
      
      <xsl:for-each select="$whereDef/odm:RangeCheck">
        
        <xsl:variable name="whereRefItemOID" select="./@def:ItemOID"/>
        <xsl:variable name="whereRefItemName" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@Name"/>
        <xsl:variable name="whereOP" select="./@Comparator"/>
        <xsl:variable name="whereRefItemCodeListOID"
          select="$g_seqItemDefs[@OID=$whereRefItemOID]/odm:CodeListRef/@CodeListOID"/>
        <xsl:variable name="whereRefItemCodeList"
          select="$g_seqCodeLists[@OID=$whereRefItemCodeListOID]"/>
        
        <xsl:call-template name="ItemGroupItemLink">
          <xsl:with-param name="ItemGroupOID" select="$ItemGroupLink"/>
          <xsl:with-param name="ItemOID" select="$whereRefItemOID"/>
          <xsl:with-param name="ItemName" select="$whereRefItemName"/>
        </xsl:call-template> 

        <xsl:choose>
          <xsl:when test="$whereOP = 'IN' or $whereOP = 'NOTIN'">
            <xsl:text> </xsl:text>
            <xsl:variable name="Nvalues" select="count(./odm:CheckValue)"/>
            <xsl:choose>
              <xsl:when test="$whereOP='IN'">
                <xsl:text>IN</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>NOT IN</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text> (</xsl:text>
            <xsl:if test="$decode='1'"><br /></xsl:if>
            <xsl:for-each select="./odm:CheckValue">
              <xsl:variable name="CheckValueINNOTIN" select="."/>
              <span class="linebreakcell">
                <xsl:call-template name="displayValue">
                  <xsl:with-param name="Value" select="$CheckValueINNOTIN"/>
                  <xsl:with-param name="DataType" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@DataType"/>
                  <xsl:with-param name="decode" select="$decode"/>
                  <xsl:with-param name="CodeList" select="$whereRefItemCodeList"/>
                </xsl:call-template>
                <xsl:if test="position() != $Nvalues">
                  <xsl:value-of select="', '"/>
                </xsl:if>
              </span>
              <xsl:if test="$decode='1'"><br /></xsl:if>
            </xsl:for-each><xsl:text>) </xsl:text>
          </xsl:when>

          <xsl:when test="$whereOP = 'EQ'">
            <xsl:variable name="CheckValueEQ" select="./odm:CheckValue"/>
            <xsl:value-of select="$Comparator_EQ"/>
            <xsl:call-template name="displayValue">
              <xsl:with-param name="Value" select="$CheckValueEQ"/>
              <xsl:with-param name="DataType" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@DataType"/>
              <xsl:with-param name="decode" select="$decode"/>
              <xsl:with-param name="CodeList" select="$whereRefItemCodeList"/>
            </xsl:call-template>
          </xsl:when>

          <xsl:when test="$whereOP = 'NE'">
            <xsl:variable name="CheckValueNE" select="./odm:CheckValue"/>
            <xsl:value-of select="$Comparator_NE"/> 
            <xsl:call-template name="displayValue">
              <xsl:with-param name="Value" select="$CheckValueNE"/>
              <xsl:with-param name="DataType" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@DataType"/>
              <xsl:with-param name="decode" select="$decode"/>
              <xsl:with-param name="CodeList" select="$whereRefItemCodeList"/>
            </xsl:call-template>
          </xsl:when>

          <xsl:otherwise>
            <xsl:variable name="CheckValueOTH" select="./odm:CheckValue"/>
            <xsl:text> </xsl:text>
            <xsl:choose>
              <xsl:when test="$whereOP='LT'">
                <xsl:value-of select="$Comparator_LT"/>
              </xsl:when>
              <xsl:when test="$whereOP='LE'">
                <xsl:value-of select="$Comparator_LE"/>
              </xsl:when>
              <xsl:when test="$whereOP='GT'">
                <xsl:value-of select="$Comparator_GT"/>
              </xsl:when>
              <xsl:when test="$whereOP='GE'">
                <xsl:value-of select="$Comparator_GE"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$whereOP"/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="displayValue">
              <xsl:with-param name="Value" select="$CheckValueOTH"/>
              <xsl:with-param name="DataType" select="$g_seqItemDefs[@OID=$whereRefItemOID]/@DataType"/>
              <xsl:with-param name="decode" select="$decode"/>
              <xsl:with-param name="CodeList" select="$whereRefItemCodeList"/>
            </xsl:call-template>            
          </xsl:otherwise>
        </xsl:choose>
        
        <xsl:if test="position() != last()">
          <xsl:text> and </xsl:text>
          <xsl:if test="$break='1'"><br/></xsl:if>
        </xsl:if>
        
      </xsl:for-each>
      
      <xsl:if test="$Nwhereclauses &gt; 1"><xsl:text>)</xsl:text></xsl:if>
      <xsl:if test="position() != last()">
        <br/><xsl:text> or </xsl:text><br/>
        <!-- only if this is not the last WhereRef in the ItemRef  -->
      </xsl:if>
      
    </xsl:for-each>
  </xsl:template>


  <!-- ************************************************************* -->
  <!-- displayValue                                                  -->
  <!-- ************************************************************* -->
  <xsl:template name="displayValue">
    <xsl:param name="Value"/>
    <xsl:param name="DataType"/>
    <xsl:param name="decode"/>
    <xsl:param name="CodeList"/>

    <xsl:if test="$DataType != 'integer' and $DataType != 'float'">
      <xsl:text>"</xsl:text><xsl:value-of select="$Value"/><xsl:text>"</xsl:text>
    </xsl:if>
    <xsl:if test="$DataType = 'integer' or $DataType = 'float'">
      <xsl:value-of select="$Value"/>
    </xsl:if>
    <xsl:if test="$decode='1'">
      <xsl:if test="$CodeList/odm:CodeListItem[@CodedValue=$Value]">
        <xsl:text> (</xsl:text>  
        <xsl:value-of
          select="$CodeList/odm:CodeListItem[@CodedValue=$Value]/odm:Decode/odm:TranslatedText"/>
        <xsl:text>)</xsl:text>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
 <!-- ************************************************************* -->
  <!-- Link to ItemGroup Item                                        -->
  <!-- ************************************************************* -->
  <xsl:template name="ItemGroupItemLink">
    <xsl:param name="ItemGroupOID"/>
    <xsl:param name="ItemOID"/>
    <xsl:param name="ItemName"/>
    <xsl:choose>
      <xsl:when test="$g_seqItemGroupDefs[@OID=$ItemGroupOID]/odm:ItemRef[@ItemOID=$ItemOID]">
        <xsl:variable name="ItemDescription" select="$g_seqItemDefs[@OID=$ItemOID]/odm:Description/odm:TranslatedText"/>
        <a>
          <xsl:attribute name="href">#<xsl:value-of select="$ItemGroupOID"/>.<xsl:value-of select="$ItemOID"/></xsl:attribute>
          <xsl:attribute name="title"><xsl:value-of select="$ItemDescription"/></xsl:attribute>
          <xsl:value-of select="$ItemName"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <!-- Item is not in current ItemGroup; only link when Item can be uniquely found in other ItemGroup -->
        <xsl:variable name="linkItems" select="count($g_seqItemGroupDefs/odm:ItemRef[@ItemOID=$ItemOID])"/>
        <xsl:choose>
          <xsl:when test="$linkItems = 1">
            <xsl:variable name="ItemDescription" select="$g_seqItemDefs[@OID=$ItemOID]/odm:Description/odm:TranslatedText"/>
            <a>
              <xsl:attribute name="href">#<xsl:value-of select="$g_seqItemGroupDefs/odm:ItemRef[@ItemOID=$ItemOID]/../@OID"/>.<xsl:value-of select="$ItemOID"/></xsl:attribute>
              <xsl:attribute name="title"><xsl:value-of select="$ItemDescription"/></xsl:attribute>
              <xsl:value-of select="$ItemName"/>
            </a>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$ItemName"/>
          </xsl:otherwise>
        </xsl:choose>
        
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="string-length(normalize-space($ItemName))=0"><span class="unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$ItemOID"/><xsl:text>]</xsl:text></span></xsl:if>
    
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Display ItemDef DecodeList                                    -->
  <!-- ************************************************************* -->
  <xsl:template name="displayItemDefDecodeList">
    <xsl:param name="itemDef"/>
    <xsl:variable name="CodeListOID" select="$itemDef/odm:CodeListRef/@CodeListOID"/>
    <xsl:variable name="CodeListDef" select="$g_seqCodeLists[@OID=$CodeListOID]"/>
    <xsl:variable name="n_items" select="count($CodeListDef/odm:CodeListItem|$CodeListDef/odm:EnumeratedItem)"/>
  	<xsl:variable name="CodeListDataType" select="$CodeListDef/@DataType" />

    <xsl:if test="$itemDef/odm:CodeListRef">

      <xsl:choose>
        <xsl:when test="$n_items &lt;= $nCodeListItemDisplay and $CodeListDef/odm:CodeListItem">
          <span class="linebreakcell"><a href="#CL.{$CodeListDef/@OID}"><xsl:value-of select="$CodeListDef/@Name"/></a></span>
          <ul class="codelist">
          <xsl:for-each select="$CodeListDef/odm:CodeListItem">
            <li class="codelist-item">
               
          	<xsl:if test="$CodeListDataType='text'">
          	  <xsl:text>&#8226;&#160;</xsl:text><xsl:value-of select="concat('&quot;', @CodedValue, '&quot;')"/>
          	</xsl:if>
          	<xsl:if test="$CodeListDataType != 'text'">
          	  <xsl:text>&#8226;&#160;</xsl:text><xsl:value-of select="@CodedValue"/>
          	</xsl:if>
          	<xsl:text> = </xsl:text>
            <xsl:value-of select="concat('&quot;', odm:Decode/odm:TranslatedText, '&quot;')"/>
            </li>
          </xsl:for-each>
          </ul>
        </xsl:when>
        <xsl:when test="$n_items &lt;= $nCodeListItemDisplay and $CodeListDef/odm:EnumeratedItem">
          <span class="linebreakcell"><a href="#CL.{$CodeListDef/@OID}"><xsl:value-of select="$CodeListDef/@Name"/></a></span>
          <ul class="codelist">
          <xsl:for-each select="$CodeListDef/odm:EnumeratedItem">
            <li class="codelist-item">
              <xsl:if test="$CodeListDataType='text'">
                <xsl:text>&#8226;&#160;</xsl:text><xsl:value-of select="concat('&quot;', @CodedValue, '&quot;')"/>
          	</xsl:if>
          	<xsl:if test="$CodeListDataType != 'text'">
          	  <xsl:text>&#8226;&#160;</xsl:text><xsl:value-of select="@CodedValue"/>
          	</xsl:if>
          	</li>
          </xsl:for-each>
          </ul>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$g_seqCodeLists[@OID=$CodeListOID]">
              <a href="#CL.{$CodeListDef/@OID}">
                <xsl:value-of select="$CodeListDef/@Name"/>
              </a>
            </xsl:when>
            <xsl:otherwise>
              <span class="unresolved"><xsl:text>[unresolved: </xsl:text><xsl:value-of select="$itemDef/odm:CodeListRef/@CodeListOID"/><xsl:text>]</xsl:text></span>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="$CodeListDef/odm:ExternalCodeList">
            <p class="linebreakcell">
              <xsl:value-of select="$CodeListDef/odm:ExternalCodeList/@Dictionary"/>
              <xsl:text> </xsl:text>
              <xsl:value-of select="$CodeListDef/odm:ExternalCodeList/@Version"/>
            </p>
          </xsl:if>
          <xsl:if test="$n_items &gt; $nCodeListItemDisplay">
            <xsl:choose>
              <xsl:when test="$n_items &gt; 1">
                <p class="linebreakcell">
                  [<xsl:value-of select="$n_items"/> Terms]
                </p>
              </xsl:when>
              <xsl:otherwise>
                <p class="linebreakcell">
                  [<xsl:value-of select="$n_items"/> Term]
                </p>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>  
        </xsl:otherwise>
      </xsl:choose>

    </xsl:if>
  </xsl:template>

	<!-- ************************************************************* -->
  <!-- Template:    setRowClassOddeven                               -->
  <!-- Description: This template sets the table row class attribute -->
  <!--              based on the specified table row number          -->
  <!-- ************************************************************* -->
  <xsl:template name="setRowClassOddeven">
    <!-- rowNum: current table row number (1-based) -->
    <xsl:param name="rowNum"/>

    <!-- set the class attribute to "tableroweven" for even rows, "tablerowodd" for odd rows -->
    <xsl:attribute name="class">
      <xsl:choose>
        <xsl:when test="$rowNum mod 2 = 0">
          <xsl:text>tableroweven</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>tablerowodd</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Template:    stringReplace                                    -->
  <!-- Description: Replace all occurences of the character(s)       -->
  <!--              'from' by 'to' in the string 'string'            -->
  <!-- ************************************************************* -->
  <xsl:template name="stringReplace" >
    <xsl:param name="string"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:choose>
      <xsl:when test="contains($string,$from)">
        <xsl:value-of select="substring-before($string,$from)"/>
        <xsl:copy-of select="$to"/>
        <xsl:call-template name="stringReplace">
          <xsl:with-param name="string"
            select="substring-after($string,$from)"/>
          <xsl:with-param name="from" select="$from"/>
          <xsl:with-param name="to" select="$to"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ***************************************** -->
  <!-- Display ISO8601                           -->
  <!-- ***************************************** -->
  <xsl:template name="displayItemDefISO8601">
    <xsl:param name="itemDef"/>
    <!-- when the datatype is one of the date/time datatypes, display 'ISO8601' in this column -->
    <xsl:if
      test="$itemDef/@DataType='date' or 
      $itemDef/@DataType='time' or 
      $itemDef/@DataType='datetime' or 
      $itemDef/@DataType='partialDate' or 
      $itemDef/@DataType='partialTime' or 
      $itemDef/@DataType='partialDatetime' or 
      $itemDef/@DataType='incompleteDatetime' or 
      $itemDef/@DataType='durationDatetime'">
      <xsl:text>ISO 8601</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Template:    lineBreak                                        -->
  <!-- Description: This template adds a line break element          -->
  <!-- ************************************************************* -->
  <xsl:template name="lineBreak">
    <xsl:element name="br">
      <xsl:call-template name="noBreakSpace"/>
    </xsl:element>
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Template:    noBreakSpace                                     -->
  <!-- Description: This template returns a no-break-space character -->
  <!-- ************************************************************* -->
  <xsl:template name="noBreakSpace">
    <!-- equivalent to &nbsp; -->
    <xsl:text/>
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- VLM buttons                                                   -->
  <!-- ************************************************************* -->
  <xsl:template name="displayButtons">
    <xsl:if test="$g_seqValueListDefs">
      <div class="buttons">
        <div class="button"><button type="button" onclick="expand_all_vlm();">Expand all VLM</button></div>
        <div class="button"><button type="button" onclick="collapse_all_vlm();">Collapse all VLM</button></div>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Link to Top                                                   -->
  <!-- ************************************************************* -->
  <xsl:template name="linkTop">
    <p class="linktop">Go to the <a href="#main">top</a> of the Define-XML document</p>
  </xsl:template>
	
  <!-- ************************************************************* -->
  <!-- Display image                                                 -->
  <!-- ************************************************************* -->
  <xsl:template name="displayImage">
    <span class="external-link-gif" />
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Display System Properties                                     -->
  <!-- ************************************************************* -->
  <xsl:template name="displaySystemProperties">
    <xsl:text>&#xA;</xsl:text>
    <xsl:comment>
      <xsl:text>&#xA;     xsl:version = "</xsl:text>
      <xsl:value-of select="system-property('xsl:version')"/>
      <xsl:text>"&#xA;</xsl:text>
      <xsl:text>     xsl:vendor = "</xsl:text>
      <xsl:value-of select="system-property('xsl:vendor')"/>
      <xsl:text>"&#xA;</xsl:text>
      <xsl:text>     xsl:vendor-url = "</xsl:text>
      <xsl:value-of select="system-property('xsl:vendor-url')"/>
      <xsl:text>"&#xA;   </xsl:text>
    </xsl:comment>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display Document Generation Date                              -->
  <!-- ************************************************************* -->
  <xsl:template name="displayODMCreationDateTimeDate">
    <p class="documentinfo">Date/Time of Define-XML document generation: <xsl:value-of select="/odm:ODM/@CreationDateTime"/></p>
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display Document Context (Define-XML v2.1)                    -->
  <!-- ************************************************************* -->
  <xsl:template name="displayContext">
    <xsl:if test="/odm:ODM/@def:Context">
      <p class="documentinfo">Define-XML Context: <xsl:value-of select="/odm:ODM/@def:Context"/></p>
    </xsl:if>  
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display Define-XML Version                                    -->
  <!-- ************************************************************* -->
  <xsl:template name="displayDefineXMLVersion">
    <p class="documentinfo">Define-XML version: <xsl:value-of select="$g_DefineVersion"/></p>
  </xsl:template>
  
  <!-- ************************************************************* -->
  <!-- Display StyleSheet Date                                       -->
  <!-- ************************************************************* -->
  <xsl:template name="displayStylesheetDate">
    <p class="stylesheetinfo">Stylesheet version: <xsl:value-of select="$STYLESHEET_VERSION"/></p>
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Generate JavaScript                                           -->
  <!-- ************************************************************* -->
  <xsl:template name="generateJavaScript">

<script type="text/javascript">
<xsl:text disable-output-escaping="yes">
<![CDATA[<!--
/**
 * With one argument, return the textContent or innerText of the element.
 * With two arguments, set the textContent or innerText of element to value.
 */
function textContent(element, value) {
  "use strict";
  var rtn;
  var content = element.textContent;  // Check if textContent is defined
  if (value === undefined) { // No value passed, so return current text
    if (content !== undefined) {
      rtn = content;
    } else {
      rtn = element.innerText;
    }
    return rtn;
  }
  else { // A value was passed, so set text
    if (content !== undefined) {
      element.textContent = value;
    } else {
      element.innerText = value;
    }
  }
}

var ITEM  = '\u00A0';
var CLOSE = '\u25BA';
var OPEN  = '\u25BC';

function toggle_submenu(e) {
  "use strict";
  if (textContent(e)===OPEN) {
    textContent(e, CLOSE);
  }
  else {
    textContent(e, OPEN);
  }

  var i;
  for (i=0; i < e.parentNode.childNodes.length; i++) {
    var c;
    c=e.parentNode.childNodes[i];
    if (c.tagName==='UL') {c.style.display=(c.style.display==='none') ? 'block' : 'none';}
   }
}

function reset_menus() {
"use strict";
  var li;
  var c;
  var i;
  var j;
  var li_tags = document.getElementsByTagName('LI');
  for (i=0; i < li_tags.length; i++) {
    li=li_tags[i];
    if ( li.className.match('hmenu-item') ){
      for (j=0; j < li.childNodes.length; j++) {
        c=li.childNodes[j];
        if ( c.tagName === 'SPAN' && c.className.match('hmenu-bullet') ) {textContent(c, ITEM);}
        }
      }
    if ( li.className.match('hmenu-submenu') ) {
      for (j=0; j < li.childNodes.length; j++) {
        c=li.childNodes[j];
        if ( c.tagName === 'SPAN' && c.className.match('hmenu-bullet') ) {textContent(c, CLOSE);}
        else if ( c.tagName === 'UL' ) { c.style.display = 'none'; }
        }
    }
  }
}

function toggle_vlm(element) {
  var child_id = element.childNodes[0].getAttribute("id");
  var vlm_rows = document.getElementsByClassName(child_id);
  for (j=0; j < vlm_rows.length; j++) {
    if (vlm_rows[j].style.display==='none') {
      vlm_rows[j].style.display=''; }
    else {
      vlm_rows[j].style.display='none'; 
      }
    }
}

function expand_all_vlm() {
  var vlm_rows = document.getElementsByClassName("vlm");
  for (j=0; j < vlm_rows.length; j++) {
      vlm_rows[j].style.display='';
    }
}

function collapse_all_vlm() {
  var vlm_rows = document.getElementsByClassName("vlm");
  for (j=0; j < vlm_rows.length; j++) {
      vlm_rows[j].style.display='none';
    }
}

/**
 * Open external documents (PDFs, ...) in a new window.
 */
document.onclick = function(e)
{
  var target = e ? e.target : window.event.srcElement;    
  while (target && !/^(a|body)$/i.test(target.nodeName))
  {
    target = target.parentNode;
  }

  if (target && target.className.match('external'))
  {
    var external = window.open(target.href);
    return external.closed;
  }
}
//-->]]>
</xsl:text>
</script>
</xsl:template>

  <!-- ************************************************************* -->
  <!-- Generate CSS                                                  -->
  <!-- ************************************************************* -->
  <xsl:variable name="COLOR_MENU_BODY_BACKGROUND">#FFFFFF</xsl:variable>
  <xsl:variable name="COLOR_MENU_BODY_FOREGROUND">#000000</xsl:variable>
  <xsl:variable name="COLOR_HMENU_TEXT">#004A95</xsl:variable>  
  <xsl:variable name="COLOR_HMENU_BULLET">#AAAAAA</xsl:variable>  
  <xsl:variable name="COLOR_CAPTION">#696969</xsl:variable>

  <xsl:variable name="COLOR_TABLE_BACKGROUND">#EEEEEE</xsl:variable>  
  <xsl:variable name="COLOR_TR_HEADER_BACK">#6699CC</xsl:variable>  
  <xsl:variable name="COLOR_TR_HEADER">#FFFFFF</xsl:variable>  
  <xsl:variable name="COLOR_TABLEROW_ODD">#FFFFFF</xsl:variable>
  <xsl:variable name="COLOR_TABLEROW_EVEN">#EEEEEE</xsl:variable>
  <xsl:variable name="COLOR_TR_VLM_BACK">#D3D3D3</xsl:variable>  

  <xsl:variable name="COLOR_BORDER">#000000</xsl:variable>  
  <xsl:variable name="COLOR_ERROR">#000000</xsl:variable>
  <xsl:variable name="COLOR_WARNING">#000000</xsl:variable>
  <xsl:variable name="COLOR_LINK">#0000FF</xsl:variable>
  <xsl:variable name="COLOR_LINK_HOVER">#FF9900</xsl:variable>
  <xsl:variable name="COLOR_LINK_VISITED">#551A8B</xsl:variable>
  
  <xsl:template name="generateCSS">
    <style type="text/css">
      .external-link-gif{
        background: 
        url(data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9gCGhErDWL4mOoAAAB6SURBVBjTbVCxDcAgDHNRP2KDY9gYO5YbWNno1mPY6E3pAJEIYCmCOCQOPogII6wNkug4d49KiXMz1EiUEg8uLBN3Ui7FVduYmxjG3JRru+facubVuIdLEV4Dzwe8V4BYg7t4Ap+d57qUnuWICBzi116v1ggfd3bM+AEZWXFvnym8EwAAAABJRU5ErkJggg==)
       no-repeat
       right center;
        padding: 8px;
      }      
      
      body{
        background-color: <xsl:value-of select="$COLOR_MENU_BODY_BACKGROUND" />;
        font-family: Verdana, Arial, Helvetica, sans-serif;
        font-size: 62.5%;
        margin: 0;
        padding: 30px;
      }
      
      h1{
        font-size: 1.6em;
        margin-left: 0;
        font-weight: bolder;
        text-align: left;
        color: <xsl:value-of select="$COLOR_CAPTION" />;
      }
      
      h1.header{
        text-align: center;
      }
      
      ul{
        margin-left: 0px;
      }
      
      a{
      color: <xsl:value-of select="$COLOR_LINK" />;
        text-decoration: underline;
      }
      a.visited{
      color: <xsl:value-of select="$COLOR_LINK_VISITED" />;
        text-decoration: underline;
      }
      a:hover{
      color: <xsl:value-of select="$COLOR_LINK_HOVER" />;
        text-decoration: underline;
      }
      a.tocItem{
      color: <xsl:value-of select="$COLOR_HMENU_TEXT" />;
      text-decoration: none;
      margin-top: 2px;
      font-size: 1.4em;
      }
      .tocItem{
      text-decoration: none;
      margin-top: 2px;
      font-size: 1.4em;
      }
      
      #menu{
        position: fixed;
        left: 0px;
        top: 10px;
        width: 20%;
        height: 96%;
        bottom: 0px;
        overflow: auto;
        background-color: <xsl:value-of select="$COLOR_MENU_BODY_BACKGROUND" />;
        color: <xsl:value-of select="$COLOR_MENU_BODY_FOREGROUND" />;
        border: 0px;
        text-align: left;
        white-space: nowrap;
      }
 
      .hmenu li{
        list-style-type: none;
        line-height: 200%;
        padding-left: 0;
      }
      .hmenu ul{
        padding-left: 14px;
        margin-left: 0;
      }
      .hmenu-item{
      }
      .hmenu-submenu{
      }
      .hmenu-bullet{
        float: left;
        width: 16px;
        color: <xsl:value-of select="$COLOR_HMENU_BULLET" />;
        font-size: 1.2em;
      }
      
      div.buttons {
        padding: 5px 0 5px 40px;
        display: inline-block;
      }
        div.button {
        padding: 5px 0 5px 0;   
      }
      
      button { 
        width: 100%;
        -webkit-border-radius: 10px;
        -moz-border-radius: 10px;
        border-radius: 10px;
        -webkit-box-shadow: 3px 3px 2px #888;
        -moz-box-shadow: 3px 3px 2px #888;
        box-shadow: 3px 3px 2px #888;
        padding: 4px 16px 4px 16px;
        display:block;
        cursor: pointer;
      }

      #main{
        position: absolute;
        left: 22%;
        top: 0px;
        overflow: auto;
        background-color: <xsl:value-of select="$COLOR_MENU_BODY_BACKGROUND" />;
        color: <xsl:value-of select="$COLOR_MENU_BODY_FOREGROUND" />;
        float: none !important;
      }
      
      ul.codelist{
        padding: 1px;
        margin-left: 1px;
        margin-right: 1px;
        margin-top: 1px;
        margin-bottom: 1px;
        
      }
      .codelist li{
        list-style-type:none;
        line-height: 200%;
        padding-left: 0;
        text-indent: -4px;
      }
      
      .codelist-caption{
        font-size: 1.4em;
        margin-top: 20px;
        margin-bottom: 10px;
        margin-left: 0;
        font-weight: bolder;
        text-align: left;
        color: <xsl:value-of select="$COLOR_CAPTION" />;
      }
      
      .codelist-item{
        list-style-type: disk;
        list-style-position: inside;
        padding-left: 0;
        padding-right: 0;
        margin: 0 0 0 0;
        }

      .codelist-item-decode{
        white-space: pre; /* CSS 2.0 */
        white-space: pre-wrap; /* CSS 2.1 */
        <!--white-space: pre-line;--> /* CSS 3.0 */
        white-space: -pre-wrap; /* Opera 4-6 */
        white-space: -o-pre-wrap; /* Opera 7 */
        white-space: -moz-pre-wrap; /* Mozilla */
        white-space: -hp-pre-wrap; /* HP Printers */
        word-wrap: break-word; /* IE 5+ */
      }      

      ul.SubClass {
        list-style-type: '- ';
        padding-left: 5;
        margin: 0 0 0 0;
      }
      ul.SubClass.li {}

      #main .docinfo{
        width: 95%;
        text-align: right;
        padding: 0px 5px;
      }
      
      div.containerbox{
        padding: 0px;
        margin: 10px auto;
        border: 0px;
        page-break-after: always;
      }
      
      .study-name{
        font-size: 1.6em;
        font-weight: bold;
        text-align: left;
        padding: 15px;
        margin-left: 20px;
        margin-top: 40px;
        margin-right: 20px;
        margin-bottom: 20px;
        color: <xsl:value-of select="$COLOR_CAPTION" />;
        border: 0px;
      }
      
      div.study-metadata{
        font-size: 1.6em;
        font-weight: bold;
        text-align: left;
        padding: 0px;
        margin-left: 0px;
        margin-top: 00px;
        margin-right: 0px;
        margin-bottom: 0px;
        color: <xsl:value-of select="$COLOR_CAPTION" />;
        border: 0px;
      }
      
      dl.study-metadata{
        width: 95%;
        padding: 5px 0px;
        font-size: 0.8em;
        color: black;
      }
      
      dl.study-metadata dt{
        clear: left;
        float: left;
        width: 200px;
        margin: 0;
        padding: 5px 5px 5px 0px;
        font-weight: bold;
      }
      
      dl.study-metadata dd{
        margin-left: 210px;
        padding: 5px;
        font-weight: normal;
        min-height: 20px;
      }
      
      div.codelist{
        page-break-after: avoid;
      }
      
      div.qval-indent {
      margin-left: 20px;
      }
      
      div.qval-indent2 {
      margin-left: 40px;
      }
      
      table{
        width: 95%;
        border-spacing: 4px;
        border: 1px solid <xsl:value-of select="$COLOR_BORDER" />;
        background-color: <xsl:value-of select="$COLOR_TABLE_BACKGROUND" />;
        margin-top: 5px;
        border-collapse: collapse;
        padding: 5px;
        empty-cells: show;
      }
      
      table caption{
        border: 0px;
        left: 20px;
        font-size: 1.4em;
        font-weight: bolder;
        color: <xsl:value-of select="$COLOR_CAPTION" />;
        margin: 10px auto;
        text-align: left;
      }
      
      .description{
        margin-left: 0px;
        color: black;
        font-weight: normal;
        font-size: 0.85em;
      }
      
      table caption .dataset{
        font-weight: normal;
        float: right;
      }

      table caption.header{
        font-size: 1.6em;
        margin-left: 0;
        font-weight: bolder;
        text-align: center;
        color: <xsl:value-of select="$COLOR_CAPTION" />;
      }
      
      table tr{
        border: 1px solid <xsl:value-of select="$COLOR_BORDER" />;
      }
      
      table tr.header{
        background-color: <xsl:value-of select="$COLOR_TR_HEADER_BACK" />;
        color: <xsl:value-of select="$COLOR_TR_HEADER" />;
        font-weight: bold;
      }
      
      table th{
        font-weight: bold;
        vertical-align: top;
        text-align: left;
        padding: 5px;
        border: 1px solid <xsl:value-of select="$COLOR_BORDER" />;
        font-size: 1.3em;
      }
      
      table th.codedvalue{
        width: 20%;
      }
      table th.length{
        width: 7%;
      }
 
      table th.label{
        width: 13%;
      }
 
      table td{
        vertical-align: top;
        padding: 5px;
        border: 1px solid <xsl:value-of select="$COLOR_BORDER" />;
        font-size: 1.2em;
        line-height: 150%;
      }

      table td.datatype{
        text-align: left;
      }
      table td.role{
        text-align: left;
      }
      table td.number{
        text-align: right;
      }
      
      tr.tablerowodd{
        background-color: <xsl:value-of select="$COLOR_TABLEROW_ODD" />;
      }
      tr.tableroweven{
        background-color: <xsl:value-of select="$COLOR_TABLEROW_EVEN" />;
      }
      
      .linebreakcell{
        vertical-align: top;
        margin-top: 3px;
        margin-bottom: 3px;
      }
      
      .nci,
      .extended{
        font-style: italic;
      }
      .super{
        vertical-align: super;
      }
      .footnote{
        font-size: 1.2em;
      }
      
      .valuelist-reference{
      vertical-align: super;
      font-size: 0.8em;
      padding-left: 5px;
      cursor: pointer;
      }
      
      .valuelist-no-reference{
      vertical-align: super;
      font-size: 0.8em;
      padding-left: 5px;
      }
      
      div.formalexpression{
        margin-top: 6px;
        margin-bottom: 6px;      
      }

      span.label{
        font-weight: bold;      
      }

      .formalexpression-reference{
        vertical-align: super;
        font-size: 0.8em;
        padding-left: 5px;
      }

      .formalexpression-code{
        font-family:"Courier New", monospace, serif;
        font-size:1.2em;
        line-height:120%;
        display:block;
        vertical-align:top;
        margin: 0px;
        padding: 5px 0 0 20px;
        white-space:pre;  /* CSS 2.0 */
        white-space: pre-wrap; /* CSS 2.1 */
        <!--white-space: pre-line; -->/* CSS 3.0 */
        white-space: -pre-wrap; /* Opera 4-6 */
        white-space: -o-pre-wrap; /* Opera 7 */
        white-space: -moz-pre-wrap; /* Mozilla */
        white-space: -hp-pre-wrap; /* HP Printers */
        word-wrap: break-word; /* IE 5+ */
      }
      
      .method-code{
        vertical-align: top;
        white-space: pre; /* CSS 2.0 */
        white-space: pre-wrap; /* CSS 2.1 */
        <!--white-space: pre-line;--> /* CSS 3.0 */
        white-space: -pre-wrap; /* Opera 4-6 */
        white-space: -o-pre-wrap; /* Opera 7 */
        white-space: -moz-pre-wrap; /* Mozilla */
        white-space: -hp-pre-wrap; /* HP Printers */
        word-wrap: break-word; /* IE 5+ */
      }

      .linktop{
        font-size: 1.2em;
        margin-top: 5px;
      }
      .documentinfo,
      .stylesheetinfo{
        font-size: 1.1em;
        line-height: 60%;
      }
      
      .invisible{
        display: none;
      }
      
      .standard-refeference {
        width: 95%;
        font-size: 1.0em;
        font-weight: bold;
        padding: 5px;
        color: <xsl:value-of select="$COLOR_CAPTION" />;
        white-space: nowrap;
      }

      .nodata{
        width: 95%;
        font-size: 1.0em;
        font-weight: bold;
        padding: 5px;
        color: <xsl:value-of select="$COLOR_WARNING" />;
        white-space: nowrap;
      }

      span.unresolved{
        color: <xsl:value-of select="$COLOR_ERROR" />;
      }
      td.unresolved{
      color: <xsl:value-of select="$COLOR_ERROR" />;
      }
      td.span.unresolved{
      color: <xsl:value-of select="$COLOR_ERROR" />;
      }
      
      span.prefix{
        font-weight: normal;
      }      

      .arm-summary{
        width: 95%;
        border-spacing: 5px;
        border-width: 1px;
        border-color: <xsl:value-of select="$COLOR_BORDER" />;
        border-style: solid solid none solid;
        background-color: <xsl:value-of select="$COLOR_TABLEROW_EVEN" />;
        font-size: 1.2em;
        line-height: 150%;
        vertical-align: top;
      }
      .arm-summary-resultdisplay{
        margin: 0px 0px 0px 0px;
        padding: 10px 10px 10px 10px;  
        border-spacing: 5px;
        border-width: 1px;
        border-color <xsl:value-of select="$COLOR_BORDER" />;
        border-style: none none solid none;
      }

      .arm-display-title{
        margin-left: 5pt;
      }
      
      .table.analysisresults-detail{
        background-color: <xsl:value-of select="$COLOR_TABLEROW_EVEN" />;
      }
      
      .arm-summary-result{
        margin-left: 20px;
        margin-top: 5px;
        margin-bottom: 5px;
      }
      th span.arm-displaytitle{
        font-weight: bold;
      }
      td span.arm-resulttitle{
        font-weight: bold;
      }
      tr.arm-analysisresult{
        background-color: <xsl:value-of select="$COLOR_TR_HEADER_BACK" />;
        color: <xsl:value-of select="$COLOR_TR_HEADER" />;
        font-weight: bold;
        border: 1px solid <xsl:value-of select="$COLOR_BORDER" />;
      }
      td.arm-label{
        font-weight: bold;
      }

      p.arm-analysisvariable{
        margin-top: 5px;
        margin-bottom: 5px;
      }
      .arm-data-reference{
        margin-top: 5px;
        margin-bottom: 5px;
      }
      
      .arm-code-context{
        padding: 5px 0px;
      }
      .arm-code-ref{
        font-size: 1.2em;
        line-height: 150%;
        padding: 5px;
      }

      .arm-code{
        font-family:"Courier New", monospace, serif;
        font-size:1.2em;
        line-height:120%;
        display:block;
        vertical-align:top;
        margin: 0px;
        padding:0px;
        white-space:pre;  /* CSS 2.0 */
        white-space: pre-wrap; /* CSS 2.1 */
        <!--white-space: pre-line; -->/* CSS 3.0 */
        white-space: -pre-wrap; /* Opera 4-6 */
        white-space: -o-pre-wrap; /* Opera 7 */
        white-space: -moz-pre-wrap; /* Mozilla */
        white-space: -hp-pre-wrap; /* HP Printers */
        word-wrap: break-word; /* IE 5+ */
      }
      

      <!-- Specific print styling -->
      @media print{
      
        @page {
          margin: 1.5cm;
        }
      
        body,
        h1,
        table caption,
        table caption.header{
          color: #000;
          background: #fff;
          float: none !important;
        }
      
        div.containerbox{
          padding: 0px;
          border: 0px;
          page-break-after: always;
        }
      
        a:link,
        a:visited{
          background: transparent;
          text-decoration: none;
          color: black;
        }
        a.external:link:after,
        #main a:visited:after{
          content: " (" attr(href) ") ";
          font-size: 100%;
          text-decoration: underline;
          font-weight: normal;
          color: black;
        }
        .external-link-gif,
        .formalexpression-reference
        .valuelist-reference{
          display: none !important;
          width: 0px;
        }
        
        table{
          border-width: 2px;
        }

        table tr.vlm{
        display: table-row !important;
        }
      
        #menu,
        .linktop{
          display: none !important;
          width: 0px;
        }
        #main{
          left: 2cm;
          float: none !important;
        }
        span.prefix{
          font-weight: normal;
        }
        
        row, ul, img {
          page-break-inside: avoid;
        }
      
      }
    </style>
  </xsl:template>

  <!-- ************************************************************* -->
  <!-- Catch the rest                                                -->
  <!-- ************************************************************* -->
  <xsl:template match="/odm:ODM/odm:Study/odm:GlobalVariables" />
  <xsl:template match="/odm:ODM/odm:Study/odm:BasicDefinitions" />
  <xsl:template match="/odm:ODM/odm:Study/odm:MetaDataVersion" />
  
</xsl:stylesheet>
