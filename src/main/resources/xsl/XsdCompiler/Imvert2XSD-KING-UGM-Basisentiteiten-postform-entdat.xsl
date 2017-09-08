<?xml version="1.0" encoding="UTF-8"?>
<!-- 
 * Copyright (C) 2016 Dienst voor het kadaster en de openbare registers
 * 
 * This file is part of Imvertor.
 *
 * Imvertor is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Imvertor is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Imvertor.  If not, see <http://www.gnu.org/licenses/>.
-->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:UML="omg.org/UML1.3"
    
    xmlns:imvert="http://www.imvertor.org/schema/system"
    xmlns:ext="http://www.imvertor.org/xsl/extensions"
    xmlns:imf="http://www.imvertor.org/xsl/functions"
   
    xmlns:ekf="http://EliotKimber/functions"
    xmlns:functx="http://www.functx.com"
    
    xmlns:StUF="http://www.stufstandaarden.nl/onderlaag/stuf0302"
    xmlns:metadata="http://www.stufstandaarden.nl/metadataVoorVerwerking" 
   
    xmlns:gml="http://www.opengis.net/gml"
    
    exclude-result-prefixes="xsl UML imvert imvert ekf"
    version="2.0">
    
    <xsl:import href="../common/Imvert-common.xsl"/>
    <xsl:import href="../common/Imvert-common-derivation.xsl"/>
    <xsl:import href="Imvert2XSD-KING-common.xsl"/>
  
    <xsl:include href="Imvert2XSD-KING-common-checksum.xsl"/>
    
    <xsl:output indent="yes" method="xml" encoding="UTF-8" exclude-result-prefixes="#all"/>
    
    <xsl:variable name="stylesheet-code">BES</xsl:variable>
    <xsl:variable name="debugging" select="imf:debug-mode($stylesheet-code)"/>

    <xsl:variable name="version" select="/schemas/schema/@version"/>
    <xsl:variable name="prefix" select="/schemas/schema/@prefix"/>
    <xsl:variable name="target-namespace" select="/schemas/schema/@target-namespace"/>
    
    <xsl:variable name="xsd-application-folder-path" select="imf:get-config-string('system','xsd-application-folder-path')"/>
    
    <xsl:variable name="schemafile-ent-name" select="concat($prefix,$version,'_ent_basis.xsd')"/>
    <xsl:variable name="schemafile-ent" select="concat($xsd-application-folder-path,'/', $schemafile-ent-name)"/>
    
    <xsl:variable name="schemafile-dat-name" select="concat($prefix,$version,'_datatypes.xsd')"/>
    <xsl:variable name="schemafile-dat" select="concat($xsd-application-folder-path,'/', $schemafile-dat-name)"/>
    
    <xsl:template match="/">
        <root/><!-- dummy output -->
        <xsl:choose>
            <xsl:when test="empty($prefix)">
                <xsl:sequence select="imf:msg(schemas,'ERROR','No prefix specified',())"/>
            </xsl:when>
            <xsl:when test="empty($target-namespace)">
                <xsl:sequence select="imf:msg(schemas,'ERROR','No namespace specified',())"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="schemas/schema/*"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="xs:schema">
        
        <!-- select the ents parts -->
        <xsl:result-document href="{$schemafile-ent}" method="xml" indent="yes" encoding="UTF-8" exclude-result-prefixes="#all">
            <xsl:apply-templates select="." mode="xsd-ent"/>
        </xsl:result-document>
        
        <!-- select the datatypes part -->
        <xsl:result-document href="{$schemafile-dat}" method="xml" indent="yes" encoding="UTF-8" exclude-result-prefixes="#all">
            <xsl:apply-templates select="." mode="xsd-dat"/>
        </xsl:result-document>
      
    </xsl:template>
    
    <xsl:function name="imf:get-taggedvalue" as="xs:string?">
        <xsl:param name="this"/>
        <xsl:param name="name"/>
        <xsl:choose>
            <!-- the imvert:packages root element is never derived. To get the tagged value directly. -->
            <xsl:when test="$this/self::imvert:packages">
                <xsl:sequence select="imf:get-tagged-value($this,$name)"/>
            </xsl:when>
            <!-- any other element may be derived. So get the tagged value from the derivation tree. -->
            <xsl:otherwise>
                <xsl:sequence select="imf:get-most-relevant-compiled-taggedvalue($this,$name)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- =================== select ent =================== -->

    <xsl:template match="xs:schema" mode="xsd-ent">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xs:include schemaLocation="{$schemafile-dat-name}"/>
            <xsl:apply-templates select=".//*:ent-part/node()" mode="resolve-checksums"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="xs:schema" mode="xsd-dat">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select=".//*:dat-part/node()" mode="resolve-checksums"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- ============== resolve checksums ============== -->
    
    <xsl:template match="*[exists(@imvert-checksum)]" mode="resolve-checksums">
        <xsl:variable name="checksum" select="@imvert-checksum"/>
        <xsl:variable name="tokens" select="tokenize($checksum,'\[SEP\]')"/>
        <xsl:choose>
            <xsl:when test="self::xs:element">
                <xsl:sequence select="imf:create-debug-comment(concat('Resolve checksum on element - ', $checksum))"/>
                <xsl:sequence select="imf:create-debug-comment(concat('Element type is ', @type))"/>
                <xsl:variable name="prefix" select="tokenize(@type,':')[1]"/>
                <xs:element type="{$prefix}:{$tokens[1]}-e">
                    <xsl:apply-templates select="@name | @minOccurs | @maxOccurs | @metadata:* | @nillable" mode="#current"/>
                    <xsl:apply-templates select="node()" mode="#current"/>
                </xs:element>
            </xsl:when>
            <xsl:when test="self::xs:extension">
                <xsl:variable name="prefix" select="tokenize(@base,':')[1]"/>
                <xsl:sequence select="imf:create-debug-comment(concat('Resolve checksum on extension - ', $checksum))"/>
                <xsl:sequence select="imf:create-debug-comment(concat('Extension base is ', @base))"/>
                <xs:extension base="{$prefix}:{$tokens[1]}">
                    <xsl:apply-templates mode="#current"/>
                </xs:extension>
            </xsl:when>
            <xsl:when test="self::xs:complexType and count(preceding::xs:complexType[@imvert-checksum = $checksum]) = 0">
                <xsl:sequence select="imf:create-debug-comment(concat('Resolve checksum on complextype - ', $checksum))"/>
                <xsl:sequence select="imf:create-debug-comment(concat('Type name is ', @name))"/>
                <xs:complexType name="{$tokens[1]}-e">
                    <xsl:apply-templates mode="#current"/>
                </xs:complexType>
            </xsl:when>
            <xsl:when test="self::xs:simpleType and count(preceding::xs:simpleType[@imvert-checksum = $checksum]) = 0">
                <xsl:sequence select="imf:create-debug-comment(concat('Resolve checksum on simpletype - ', $checksum))"/>
                <xsl:sequence select="imf:create-debug-comment(concat('Type name is ', @name))"/>
                <xs:simpleType name="{$tokens[1]}">
                    <xsl:apply-templates mode="#current"/>
                </xs:simpleType>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="imf:create-debug-comment(concat('Resolve checksum, removed duplicate - ', $checksum))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="node()" mode="resolve-checksums">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@*" mode="resolve-checksums">
        <xsl:copy/>
    </xsl:template>
    
</xsl:stylesheet>
