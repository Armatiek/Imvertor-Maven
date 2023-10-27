package nl.imvertor.common.file;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLGenerator.Feature;
import com.fasterxml.jackson.dataformat.yaml.YAMLMapper;

import nl.imvertor.common.Configurator;
import nl.imvertor.common.exceptions.ConfiguratorException;

public class JsonFile extends AnyFile {
	
	private static final long serialVersionUID = 5224759842363118591L;

	protected static final Logger logger = Logger.getLogger(JsonFile.class);
	
	private HashMap<String,String> parms = new HashMap<String,String>();
	
	public static void main(String[] args) {
		JsonFile jsonInputFile = new JsonFile("d:\\projects\\validprojects\\BRO\\input\\SKOS-JSON\\aquo-data.json");
		XmlFile xmlOutputFile = new XmlFile("c:/temp/sample.xml");
		JsonFile jsonOutputFile = new JsonFile("c:/temp/sample.json");
		try {
			jsonInputFile.toXml(xmlOutputFile);
			jsonOutputFile.setIndent(true);
			xmlOutputFile.toJson(jsonOutputFile);
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		System.out.println("done");
	
	}
	
	public JsonFile(File file) throws IOException {
		super(file);
    }
	public JsonFile(String pathname) {
		super(pathname);
	}
	
	/**
	 * Determines whether deviations from the syntax of RFC7159 are permitted.
	 * 
	 * See <a href="https://www.w3.org/TR/xpath-functions-31/#func-json-to-xml">W3C spec</a>
	 * 
	 **/
	public void setLiberal(Boolean value) {
		parms.put("liberal", value.toString());
	}
	
	/**
	 * Determines the policy for handling duplicate keys in a JSON object. To determine whether keys are duplicates, they are compared using the Unicode codepoint collation, after expanding escape sequences, unless the escape option is set to true, in which case keys are compared in escaped form.
	 * 
	 * See <a href="https://www.w3.org/TR/xpath-functions-31/#func-json-to-xml">W3C spec</a>
	 * 
	 **/
	public void setDuplicates(String value) {
		parms.put("duplicates", value);
	}
	
	/**
	 * 
	 * Determines whether the generated XML tree is schema-validated.
	 * 
	 * See <a href="https://www.w3.org/TR/xpath-functions-31/#func-json-to-xml">W3C spec</a>
	 * 
	 **/
	public void setValidate(Boolean value) {
		parms.put("validate", value.toString());
	}
	
	/**
	 * Determines whether special characters are represented in the XDM output in backslash-escaped form.
	 * 
	 * See <a href="https://www.w3.org/TR/xpath-functions-31/#func-json-to-xml">W3C spec</a>
	 * 
	 **/
	public void setEscape(Boolean value) {
		parms.put("escape", value.toString());
	}
	
	/**
	 * Determines whether the json generated from XML must be indented.
	 * 
	 * See <a href="https://www.w3.org/TR/xpath-functions-31/#func-xml-to-json">W3C spec</a>
	 * 
	 **/
	public void setIndent(Boolean value) {
		parms.put("indent", value.toString());
	}
	
	/**
     * Create an XML representation of this Json file. 
     * 
     */
    public void toXml(XmlFile targetFile) throws Exception {
		XmlFile xmlFile = new XmlFile(Configurator.getInstance().getResource("static/xsl/JsonFile/jsonToXml.xml")); // dit file wordt gebruikt om het proces op te starten.
		XslFile xslFile = new XslFile(Configurator.getInstance().getResource("static/xsl/JsonFile/jsonToXml.xsl"));
		
		parms.put("jsonstring", getContent());
		
		xslFile.transform(xmlFile, targetFile, parms);
    }
    
    /**
     * Set the content to the Json serialization of the specified XML file. 
     * 
     * The XML file must adhere to XML schema <a href="https://www.w3.org/TR/xpath-functions-31/#json-to-xml-mapping">here</a>
     * 
     */
    public void fromXml(XmlFile xmlFile) throws Exception {
 		fromXml(xmlFile,false);
     }
    public void fromXml(XmlFile xmlFile, Boolean pretty) throws Exception {
 		XslFile xslFile = new XslFile(Configurator.getInstance().getResource("static/xsl/JsonFile/xmlToJson.xsl"));
 		xslFile.transform(xmlFile, this, parms);
 		if (pretty) this.prettyPrint();
     }
    
    /**
	 * Validate the contents of this file. 
	 * 
	 * When errors occur, return that error message.
	 * 
	 * @param jsonString
	 * @return True when succeeds, no validation errors.
	 * @throws ConfiguratorException 
	 * @throws IOException 
	 */
	public boolean validate() throws IOException, ConfiguratorException {
		String jsonString = getContent();
		try {
			Matcher m = Pattern.compile("^\\s*?(\\S)").matcher(jsonString);
			String firstChar = (m.find()) ? m.group(1) : ""; 
			if (firstChar.equals("{")) {
				JSONObject object = new JSONObject(jsonString); // Convert text to object
				// also check if this is an error map, generated by the JsonFile in converting from XML to Json.
				if (object.has("source") && object.get("source").equals("W3CJson"))
					throw new Exception("JSON transform error: " + object.getString("description"));
			} else if (firstChar.equals("["))
				new JSONArray(jsonString); // Convert text to array
			else
				throw new Exception("Unrecognized JSON type: \"" + firstChar + "\"");
		} catch (Exception e) {
			Configurator.getInstance().getRunner().error(logger, "Invalid JSON: \"" + e.getMessage() + "\"", null, "", "IJ");
			return false;
		}
		return true;
	}
	
    /**
     * Create a Yaml representation of this Json file. 
     * 
     * @param configurator
     * @param resultYamlFile
     * @return
     * @throws Exception 
     */
    public boolean toYaml(YamlFile resultYamlFile) throws Exception {
		try {
			 // parse JSON
	        JsonNode jsonNodeTree = new ObjectMapper().readTree(getContent());
	        // save it as YAML
	        YAMLMapper m = new YAMLMapper();
	        m.disable(Feature.WRITE_DOC_START_MARKER);
	        m.enable(Feature.ALWAYS_QUOTE_NUMBERS_AS_STRINGS); // #issues/244
	        m.disable(Feature.MINIMIZE_QUOTES); // #244
	        String jsonAsYaml = m.writeValueAsString(jsonNodeTree);
	        resultYamlFile.setContent(jsonAsYaml);
        } catch (Exception e) {
			throw new Exception("Error parsing Json: " + e.getLocalizedMessage());
		}
		return true;
	}
    
    public void prettyPrint() throws IOException {
    	ObjectMapper mapper = new ObjectMapper();
        Object rawJson = mapper.readValue(getContent(), Object.class);
        String prettyJson = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(rawJson);
        setContent(prettyJson);
    }
}
